export class OtpService {
  /**
   * Generate a 6-digit OTP code
   */
  generateOtpCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Get OTP expiry time (10 minutes from now)
   */
  getOtpExpiry(): Date {
    return new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  }

  /**
   * Check if OTP is expired
   */
  isOtpExpired(otpExpiry: Date | null): boolean {
    if (!otpExpiry) return true;
    return new Date() > otpExpiry;
  }
}
