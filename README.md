# RailsUI Auto Poster

An automated Twitter/X posting bot that shares Rails, Tailwind, and UI development insights. Built specifically for promoting RailsUI components with authentic, first-person developer experiences.

## Features

- 🤖 **Smart Timing**: Posts 1-2 times per week automatically
- 📝 **100+ Tweets**: Varied content across 5 categories
- 🚀 **Rails 8 Compatible**: Latest Rails features and patterns
- 👤 **Human Voice**: First-person, authentic developer experiences
- 🔒 **Safe Demo Mode**: Test content without posting
- 🎯 **Anti-Spam**: Won't post too frequently
- ☁️ **GitHub Actions**: Free cloud hosting

## Content Categories

1. **Rails Tips**: Rails 8 features, best practices, and development patterns
2. **Tailwind Tips**: CSS utilities, design patterns, and modern styling
3. **UI Insights**: Design principles, UX patterns, and interface wisdom
4. **Building Public**: Solo dev experiences, product lessons, and startup truths
5. **Rails 8 Features**: Solid Queue, Kamal, Propshaft, and new Rails 8 capabilities

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/yourusername/railsui_poster.git
cd railsui_poster
bundle install
```

### 2. Test Locally (Optional)

```bash
# See what would be posted
ruby auto_poster.rb demo

# Check posting status
ruby auto_poster.rb status
```

### 3. Get Twitter/X API Credentials

1. Go to [Twitter Developer Portal](https://developer.twitter.com/en/portal/dashboard)
2. Create a new app (or use existing)
3. Generate API keys and tokens
4. You'll need:
   - API Key (Consumer Key)
   - API Key Secret (Consumer Secret)
   - Access Token
   - Access Token Secret

### 4. Push to GitHub

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

## GitHub Actions Setup

### 1. Add Secrets to GitHub

Go to your repository on GitHub:
1. Click **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these four secrets:

| Secret Name | Value |
|-------------|-------|
| `X_API_KEY` | Your Twitter API Key |
| `X_API_KEY_SECRET` | Your Twitter API Key Secret |
| `X_ACCESS_TOKEN` | Your Twitter Access Token |
| `X_ACCESS_TOKEN_SECRET` | Your Twitter Access Token Secret |

### 2. Enable Actions

1. Go to **Actions** tab in your repository
2. Enable GitHub Actions if prompted
3. The workflow will run automatically twice daily (9 AM and 5 PM UTC)

### 3. Manual Trigger (Optional)

You can manually trigger the workflow:
1. Go to **Actions** tab
2. Click on "Auto Poster" workflow
3. Click **Run workflow** → **Run workflow**

## Usage

### Local Commands

```bash
# Show what would be posted (safe to run anytime)
ruby auto_poster.rb demo

# Check posting status and timing
ruby auto_poster.rb status

# Actually post (only if it's time)
ruby auto_poster.rb post

# Show help
ruby auto_poster.rb
```

### GitHub Actions

Once set up, the bot will:
- Run twice daily at 9 AM and 5 PM UTC
- Only post if it's been 3-7 days since last post
- Track timing in `posting_schedule.json`
- Log all posts in `posted_content.log`

## Timing Logic

- **Minimum**: 3 days between posts
- **Maximum**: 7 days before guaranteed post
- **Frequency**: 1-2 times per week on average
- **Probability**: Increases over time between min/max days

## Files

- `auto_poster.rb` - Main bot script
- `posting_schedule.json` - Tracks last post time (auto-created)
- `posted_content.log` - Logs all posted content (auto-created)
- `.github/workflows/auto_poster.yml` - GitHub Actions workflow
- `.env.example` - Template for local environment variables

## Customization

### Adding New Content

Edit the `CONTENT_BANK` hash in `auto_poster.rb`:

```ruby
CONTENT_BANK = {
  rails_tip: [
    "Your new Rails tip here",
    # ... more tips
  ],
  # ... other categories
}
```

### Changing Templates

Edit the `CONTENT_TEMPLATES` array to modify how content is formatted:

```ruby
CONTENT_TEMPLATES = [
  {
    type: :rails_tip,
    templates: [
      "Your new template: CONTENT_PLACEHOLDER",
      # ... more templates
    ]
  }
]
```

### Adjusting Timing

Modify the timing logic in the `should_post_today?` method:

```ruby
# Current: 3-7 days apart
min_days = 3
max_days = 7

# Example: Daily posting
min_days = 1
max_days = 1
```

## Troubleshooting

### Workflow Not Running

1. Check that GitHub Actions is enabled in your repository
2. Verify all four secrets are added correctly
3. Check the Actions tab for error messages

### API Errors

1. Verify your Twitter API credentials are correct
2. Ensure your Twitter developer app has write permissions
3. Check that your access tokens aren't expired

### Rate Limiting

The bot respects Twitter's rate limits and won't post too frequently. If you see rate limit errors, the timing logic will prevent posting until it's safe.

## Local Development

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env

# Test without posting
ruby auto_poster.rb demo
```

### Testing

```bash
# Run a demo to see what would be posted
ruby auto_poster.rb demo

# Check timing and status
ruby auto_poster.rb status
```

## Security

- Never commit API keys to git
- Use GitHub Secrets for credentials
- The `.env` file is gitignored
- All sensitive data is handled securely

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your content or improvements
4. Test with `ruby auto_poster.rb demo`
5. Submit a pull request

## License

MIT License - feel free to use this for your own projects!

## Credits

Built for [RailsUI](https://railsui.com) - Premium Rails UI components and templates.