# gmailsender

## How to use

```
gem install bundler
bundle install
python oauth2.py \
  --user=GMAIL_ADDR \
  --client_id=GOOGLE_OAUTH2_CLIENT_ID \
  --client_secret=GOOGLE_OAUTH2_CLIENT_SECRET \
  --generate_oauth2_token # retrieve refresh token
vi config.yaml
bundle exec ruby gmailsender.rb
```
