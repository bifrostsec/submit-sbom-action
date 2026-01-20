import * as core from '@actions/core'
import {SubmitConfig} from './types'
import {validateSbomFile, readSbomFile} from './validator'
import {submitSbom} from './submitter'

/**
 * Parses action inputs into configuration object
 * @returns SubmitConfig with all parsed inputs
 */
function getConfig(): SubmitConfig {
    const retryAttempts = parseInt(core.getInput('retry-attempts') || '3', 10)
    const retryDelay = parseInt(core.getInput('retry-delay') || '5', 10)

    // Validate numeric inputs
    if (isNaN(retryAttempts) || retryAttempts < 1) {
        throw new Error(`Invalid input "retry-attempts": expected a positive integer, got "${core.getInput('retry-attempts')}"`)
    }
    if (isNaN(retryDelay) || retryDelay < 0) {
        throw new Error(`Invalid input "retry-delay": expected a non-negative integer, got "${core.getInput('retry-delay')}"`)
    }

    return {
        apiToken: core.getInput('api-token', {required: true}),
        service: core.getInput('service', {required: true}),
        serviceVersion: core.getInput('service-version', {required: true}),
        image: core.getInput('image', {required: true}),
        sbomPath: core.getInput('sbom-path', {required: true}),
        retryAttempts,
        retryDelay,
        apiHost: core.getInput('api-host') || 'https://portal.bifrostsec.com',
    }
}

/**
 * Main function for the action
 * @returns Promise that resolves when action is complete
 */
export async function run(): Promise<void> {
    // Parse inputs early so we can access failOnError in catch block
    const failOnError = core.getInput('fail-on-error') !== 'false'

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
        core.setOutput('success', result.success.toString())

        // Fail the action if submission was not successful
        if (!result.success) {
            const message = `Failed to submit SBOM after ${config.retryAttempts} attempts`
            core.setFailed(message)
        }
    } catch (error) {
        // Handle any unexpected errors
        const message = error instanceof Error ? error.message : String(error)
        core.setFailed(message)
    }
}
