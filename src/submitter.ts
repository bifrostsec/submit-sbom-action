import * as core from '@actions/core'
import { HttpClient } from '@actions/http-client'
import { BearerCredentialHandler } from '@actions/http-client/lib/auth'
import { SubmitConfig, SubmitResult } from './types'

/**
 * Builds the API URL with URL-encoded image parameter
 * @param service - Service name
 * @param version - Service version
 * @param image - Container image name (will be URL encoded)
 * @returns Complete API URL
 */
function buildApiUrl(
  service: string,
  version: string,
  image: string
): string {
  // URL encode the image parameter (replaces jq -sRr @uri)
  const encodedImage = encodeURIComponent(image)
  return `https://portal.bifrostsec.com/api/v2/service/${service}/version/${version}/sbom?image=${encodedImage}`
}

/**
 * Attempts to submit SBOM to the API
 * @param client - HTTP client with bearer authentication
 * @param url - API endpoint URL
 * @param sbomContent - SBOM file content to submit
 * @returns SubmitResult with status and response
 */
async function attemptSubmit(
  client: HttpClient,
  url: string,
  sbomContent: string
): Promise<SubmitResult> {
  try {
    const response = await client.post(url, sbomContent, {
      'Content-Type': 'application/json'
    })

    const statusCode = response.message.statusCode || 0
    const body = await response.readBody()

    return {
      success: statusCode >= 200 && statusCode < 300,
      httpStatus: statusCode,
      responseBody: body
    }
  } catch (error) {
    // Network errors or other exceptions
    const errorMessage = error instanceof Error ? error.message : String(error)
    return {
      success: false,
      httpStatus: 0,
      responseBody: `Network error: ${errorMessage}`
    }
  }
}

/**
 * Sleeps for specified seconds
 * @param seconds - Number of seconds to sleep
 */
function sleep(seconds: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, seconds * 1000))
}

/**
 * Submits SBOM to Bifrost API with retry logic
 * @param config - Submit configuration
 * @param sbomContent - SBOM file content
 * @returns SubmitResult with final status
 */
export async function submitSbom(
  config: SubmitConfig,
  sbomContent: string
): Promise<SubmitResult> {
  core.info('Submitting SBOM to Bifrost API...')
  core.info(`Service: ${config.service}`)
  core.info(`Version: ${config.version}`)
  core.info(`Image: ${config.image}`)

  // Create HTTP client with Bearer authentication
  const bearerCredentialHandler = new BearerCredentialHandler(config.apiToken)
  const client = new HttpClient('@bifrost/submit-sbom-action', [
    bearerCredentialHandler
  ])

  // Build API URL
  const url = buildApiUrl(config.service, config.version, config.image)

  // Retry loop
  let lastResult: SubmitResult | null = null

  for (let attempt = 1; attempt <= config.retryAttempts; attempt++) {
    core.info(`Attempt ${attempt} of ${config.retryAttempts}...`)

    const result = await attemptSubmit(client, url, sbomContent)
    lastResult = result

    if (result.success) {
      core.info('✓ SBOM successfully submitted to Bifrost')
      core.info(`HTTP Status: ${result.httpStatus}`)
      core.info(`Response: ${result.responseBody}`)
      return result
    } else {
      core.warning(`✗ Failed to submit SBOM (HTTP ${result.httpStatus})`)
      core.warning(`Response: ${result.responseBody}`)

      if (attempt < config.retryAttempts) {
        core.info(`Retrying in ${config.retryDelay} seconds...`)
        await sleep(config.retryDelay)
      }
    }
  }

  // All retries failed
  core.error('All retry attempts failed')
  return lastResult!
}
