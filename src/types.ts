/**
 * Configuration for SBOM submission
 */
export interface SubmitConfig {
    apiToken: string
    service: string
    serviceVersion: string
    image: string
    sbomPath: string
    retryAttempts: number
    retryDelay: number
    apiHost: string
}

/**
 * Result of SBOM submission
 */
export interface SubmitResult {
    success: boolean
    httpStatus: number
    responseBody: string
}

/**
 * Options for retry logic
 */
export interface RetryOptions {
    maxAttempts: number
    delaySeconds: number
}
