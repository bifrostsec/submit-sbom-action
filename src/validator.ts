import * as core from '@actions/core'
import * as fs from 'fs'
import * as path from 'path'

/**
 * Validates that the SBOM file exists and is readable
 * @param sbomPath - Path to the SBOM file
 * @throws Error if file doesn't exist or isn't readable
 */
export function validateSbomFile(sbomPath: string): void {
    core.info(`Validating SBOM file: ${sbomPath}`)

    // Resolve to absolute path
    const absolutePath = path.resolve(sbomPath)

    // Check if file exists
    if (!fs.existsSync(absolutePath)) {
        throw new Error(`SBOM file not found at ${sbomPath}`)
    }

    // Check if it's a file (not a directory)
    const stats = fs.statSync(absolutePath)
    if (!stats.isFile()) {
        throw new Error(`Path ${sbomPath} is not a file`)
    }

    // Log success with file size
    core.info(`✓ SBOM file found: ${sbomPath}`)

    // Warn if file is empty
    const fileSize = stats.size
    if (fileSize === 0) {
        core.warning('SBOM file is empty (0 bytes)')
    }
}

/**
 * Reads the SBOM file contents
 * @param sbomPath - Path to the SBOM file
 * @returns File contents as string
 */
export function readSbomFile(sbomPath: string): string {
    const absolutePath = path.resolve(sbomPath)
    return fs.readFileSync(absolutePath, 'utf-8')
}
