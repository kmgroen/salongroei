/**
 * Image Versioning System
 *
 * Manages image versions to prevent frontend caching issues.
 * When an image is updated, increment its version number here.
 */

export const IMAGE_VERSIONS: Record<string, number> = {
  // Blog images
  '/images/blog/no-shows.jpg': 1,
  '/images/blog/online-booking.jpg': 1,
  '/images/blog/waitlist.jpg': 1,
  '/images/blog/double-bookings.jpg': 1,
  '/images/blog/capacity-planning.jpg': 1,

  // Infographics
  '/images/infographics/no-shows-statistics-infographic.png': 4,
  '/images/infographics/online-booking-benefits-infographic.png': 4,
  '/images/infographics/waitlist-management-infographic.png': 4,
  '/images/infographics/prevent-double-bookings-infographic.png': 4,
  '/images/infographics/capacity-planning-infographic.png': 4,

  // Hero and landing page images
  '/images/hero-illustration.svg': 1,
  '/images/hero-background.svg': 1,

  // Tool logos
  '/images/tools/glossgenius-logo.svg': 1,
  '/images/tools/phorest-logo.svg': 1,
  '/images/tools/fresha-logo.svg': 1,
  '/images/tools/treatwell-logo.svg': 1,
  '/images/tools/planty-logo.svg': 1,
  '/images/tools/salonized-logo.svg': 1,
  '/images/tools/square-logo.svg': 1,
  '/images/tools/vagaro-logo.svg': 1,
  '/images/tools/booksy-logo.svg': 1,
  '/images/tools/timely-logo.svg': 1,
};

/**
 * Get versioned URL for an image
 *
 * @param imagePath - Path to the image (e.g., '/images/blog/no-shows.jpg')
 * @returns Versioned URL with query parameter (e.g., '/images/blog/no-shows.jpg?v=1')
 *
 * @example
 * ```astro
 * import { getVersionedImageUrl } from '@/utils/imageVersion'
 *
 * <img src={getVersionedImageUrl('/images/blog/no-shows.jpg')} alt="..." />
 * ```
 */
export function getVersionedImageUrl(imagePath: string): string {
  const version = IMAGE_VERSIONS[imagePath] || 1;
  return `${imagePath}?v=${version}`;
}

/**
 * Get version number for an image
 *
 * @param imagePath - Path to the image
 * @returns Version number (defaults to 1 if not found)
 */
export function getImageVersion(imagePath: string): number {
  return IMAGE_VERSIONS[imagePath] || 1;
}

/**
 * Update image version (for build scripts)
 *
 * This function is intended for use in build/deployment scripts
 * when regenerating images (like infographics).
 *
 * @param imagePath - Path to the image
 * @param newVersion - New version number (optional, will increment by 1 if not provided)
 */
export function updateImageVersion(imagePath: string, newVersion?: number): void {
  const currentVersion = IMAGE_VERSIONS[imagePath] || 1;
  IMAGE_VERSIONS[imagePath] = newVersion ?? currentVersion + 1;
}

/**
 * Batch update versions for all images in a directory
 *
 * @param directory - Directory prefix (e.g., '/images/infographics/')
 * @param newVersion - New version number (optional, will increment by 1 if not provided)
 */
export function updateDirectoryVersions(directory: string, newVersion?: number): void {
  Object.keys(IMAGE_VERSIONS).forEach(path => {
    if (path.startsWith(directory)) {
      const currentVersion = IMAGE_VERSIONS[path] || 1;
      IMAGE_VERSIONS[path] = newVersion ?? currentVersion + 1;
    }
  });
}
