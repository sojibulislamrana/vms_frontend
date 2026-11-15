# Deploy Stark Fleet to Vercel

The frontend is a Flutter Web static site. The Spring Boot API is deployed separately from the backend repository.

## Vercel project

1. Import `vms-frontend` from GitHub.
2. Use the repository root as the Vercel **Root Directory**.
3. Add these environment variables in Vercel:

   | Name | Value |
   | --- | --- |
   | `API_BASE_URL` | Public origin of the deployed Spring API, with no trailing slash |
   | `SUPABASE_URL` | Supabase project URL |
   | `SUPABASE_ANON_KEY` | Supabase publishable key |

   `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` are accepted as alternatives for the Supabase variables.

4. Deploy. `vercel.json` runs `vercel-build.sh`, which installs Flutter stable, builds the web release, and publishes `build/web`.
5. In Supabase **Authentication → URL Configuration**, set the Vercel production origin as the Site URL and add it to Redirect URLs. Add `http://127.0.0.1:8094/**` for local signup and password reset.

## Local frontend

Copy `.env.example` to `.env.local`, fill in the project URL and publishable key, and set `API_BASE_URL` to your local or deployed API. Then run:

```sh
./run-web.sh
```

This launcher passes the values as Dart defines. Running `flutter run` directly does not load `.env.local` and shows the app's “Authentication is not configured” message.

Google sign-in also needs a Google OAuth Web client ID and secret configured in Supabase **Authentication → Sign In / Providers → Google**. In Google Cloud, use the callback URL shown by Supabase as the authorized redirect URI.
