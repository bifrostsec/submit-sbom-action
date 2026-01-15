import * as core from '@actions/core'
import {SubmitConfig} from './types'
import {validateSbomFile, readSbomFile} from './validator'
import {submitSbom} from './submitter'

/**
 * Parses action inputs into configuration object
 * @returns SubmitConfig with all parsed inputs
 */
function getConfig(): SubmitConfig {
    return {
        apiToken: core.getInput('api-token', {required: true}),
        service: core.getInput('service', {required: true}),
        version: core.getInput('version', {required: true}),
        image: core.getInput('image', {required: true}),
        sbomPath: core.getInput('sbom-path', {required: true}),
        retryAttempts: parseInt(core.getInput('retry-attempts') || '3', 10),
        retryDelay: parseInt(core.getInput('retry-delay') || '5', 10)
    }
}

/**
 * Main function for the action
 * @returns Promise that resolves when action is complete
 */
export async function run(): Promise<void> {
    try {
        // Parse inputs
        const config = getConfig()

        // Validate SBOM file exists
        validateSbomFile(config.sbomPath)

        // Read SBOM file contents
        const sbomContent = readSbomFile(config.sbomPath)

        // Submit SBOM with retry logic
        const result = await submitSbom(config, sbomContent)

        // Set outputs
        core.setOutput('http-status', result.httpStatus.toString())
        core.setOutput('response-body', result.responseBody)
        core.setOutput('success', result.success.toString())

        // Fail the action if submission was not successful
        if (!result.success) {
            core.setFailed(
                `Failed to submit SBOM after ${config.retryAttempts} attempts`
            )
        }
    } catch (error) {
        // Handle any unexpected errors
        if (error instanceof Error) {
            core.setFailed(error.message)
        } else {
            core.setFailed(String(error))
        }
    }
}
