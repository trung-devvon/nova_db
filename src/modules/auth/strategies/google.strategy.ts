import passport from 'passport';
import { Strategy as GoogleStrategy, Profile, VerifyCallback } from 'passport-google-oauth20';
import { config } from '@/core/config';
import prisma from '@/core/db';
import { AuthProvider } from '@prisma/client';

passport.use(
  new GoogleStrategy(
    {
      clientID: config.GOOGLE_CLIENT_ID,
      clientSecret: config.GOOGLE_CLIENT_SECRET,
      callbackURL: config.GOOGLE_CALLBACK_URL,
    },
    async (accessToken: string, refreshToken: string, profile: Profile, done: VerifyCallback) => {
      try {
        const email = profile.emails?.[0]?.value;

        if (!email) {
          return done(new Error('No email found in Google profile'), undefined);
        }

        // Find or create user
        let user = await prisma.user.findUnique({
          where: { email },
        });

        if (!user) {
          // Create new user from Google profile
          user = await prisma.user.create({
            data: {
              email,
              name: profile.displayName,
              avatar: profile.photos?.[0]?.value,
              authProvider: AuthProvider.GOOGLE,
              isVerified: true, // Google users are auto-verified
            },
          });
        } else if (user.authProvider !== AuthProvider.GOOGLE) {
          // User exists with LOCAL provider
          return done(new Error('Email đã được đăng ký bằng tài khoản thông thường'), undefined);
        }

        return done(null, user);
      } catch (error) {
        return done(error as Error, undefined);
      }
    }
  )
);

export default passport;
