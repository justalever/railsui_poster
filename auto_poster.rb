#!/usr/bin/env ruby
require 'x'
require 'dotenv/load'
require 'json'
require 'time'
require 'openai'

class AutoPoster
  # Fallback content templates (used if AI fails)
  FALLBACK_TEMPLATES = [
    {
      type: :rails_tip,
      templates: [
        "CONTENT_PLACEHOLDER\n\nJust used this pattern in my latest Rails UI component 🚀",
        "Rails tip: CONTENT_PLACEHOLDER\n\nSaved me hours while building Rails UI templates",
        "CONTENT_PLACEHOLDER\n\nThis is why I love Rails development so much"
      ]
    },
    {
      type: :tailwind_tip,
      templates: [
        "CONTENT_PLACEHOLDER\n\nUsing this in many components now",
        "CONTENT_PLACEHOLDER\n\nGame changer for Rails UI"
      ]
    },
    {
      type: :ui_insight,
      templates: [
        "UI realization: CONTENT_PLACEHOLDER\n\nChanged how I approach every Rails UI design",
        "CONTENT_PLACEHOLDER\n\nThis thinking transformed my Rails UI components"
      ]
    },
    {
      type: :building_public,
      templates: [
        "CONTENT_PLACEHOLDER",
        "CONTENT_PLACEHOLDER\n\nThe reality of shipping as a solo dev 🛠️",
        "Product lesson: CONTENT_PLACEHOLDER\n\nLearned this the hard way"
      ]
    },
    {
      type: :rails_8_feature,
      templates: [
        "Rails 8: CONTENT_PLACEHOLDER\n\nAlready loving this in my setup",
        "CONTENT_PLACEHOLDER\n\nRails is changing how I build everything",
        "Rails 8 feature: CONTENT_PLACEHOLDER\n\nExactly what I needed"
      ]
    },
    {
      type: :stimulus_component,
      templates: [
        "CONTENT_PLACEHOLDER\n\nJust added this to the component library",
        "Stimulus discovery: CONTENT_PLACEHOLDER\n\nMakes my Rails apps way more interactive",
        "CONTENT_PLACEHOLDER\n\nThis railsui-stimulus component is becoming a favorite"
      ]
    },
    {
      type: :icon_gem,
      templates: [
        "CONTENT_PLACEHOLDER\n\nThe railsui_icon gem makes this so simple",
        "Icon tip: CONTENT_PLACEHOLDER\n\nNo more SVG hunting",
        "CONTENT_PLACEHOLDER\n\nWhy I love the railsui_icon gem"
      ]
    }
  ]

  FALLBACK_CONTENT = {
    rails_tip: [
      "Rails 8's authentication generator creates a complete auth system in seconds",
      "Use `&.` safe navigation everywhere. `@user&.name` is cleaner than checking nil first",
      "Turbo 8 morphing makes page updates feel instant. Set `data-turbo-action='morph'` on your links"
    ],
    tailwind_tip: [
      "Tailwind v4 container queries are perfect for responsive components. `@container (min-width: 20rem)` beats media queries",
      "New `size-*` utilities in v4 are cleaner than `w-* h-*` for square elements",
      "Tailwind v4's CSS-first approach eliminates config file bloat. Just write CSS",
      "Modern `text-wrap: balance` for headlines prevents awkward line breaks in v4"
    ],
    ui_insight: [
      "White space isn't empty space. It's a design element that guides attention",
      "Users scan in F-patterns. Put important stuff top-left and down the left edge",
      "Loading states prevent perceived slowness. Show something immediately"
    ],
    building_public: [
      "Spent 4 hours perfecting a button component. Details compound",
      "User feedback beats my assumptions every time. Always test ideas first",
      "Shipping broken beats perfect unshipped. You can't improve what's not live",
      "Building in public keeps me accountable. Harder to quit when people watch"
    ],
    rails_8_feature: [
      "Solid Queue eliminates Redis for background jobs. One less service to manage",
      "Rails 8's authentication generator creates secure auth in seconds",
      "Kamal deployment is a game changer. Docker to production in one command",
      "Rails 8's built-in rate limiting protects apps without external gems"
    ],
    stimulus_component: [
      "RailsUI Stimulus clipboard component copies text with one click. No more custom JS",
      "The modal component from railsui-stimulus handles focus trapping perfectly",
      "RailsUI dropdown component beats writing custom JavaScript every time",
      "Toast notifications with railsui-stimulus are dead simple to implement"
    ],
    icon_gem: [
      "railsui_icon gem renders heroicons inline. No more asset pipeline headaches",
      "Love the variant support in railsui_icon. Solid, outline, mini, micro all work",
      "Custom icon paths in railsui_icon let me use my own SVGs easily",
      "Default classes in railsui_icon save me from repeating Tailwind v4 utilities"
    ]
  }

  # AI prompts for different content types
  AI_PROMPTS = {
    rails_tip: "Write a complete tweet about a Rails tip like you're sharing with dev friends. Be specific about a real problem you solved. Naturally mention Rails UI if relevant. Avoid: 'game changer', 'boost', 'leverage', 'seamless', 'streamline', 'elevate'. Use simple words. Sound frustrated or excited about something concrete. Under 200 chars. Examples: 'Spent hours debugging N+1 queries. `includes` fixed it instantly.', 'Rails 8 auth generator saved my weekend. No more Devise config hell', 'Finally figured out Turbo morphing. Forms feeling quite snappy now'",

    tailwind_tip: "Write a complete tweet about a modern Tailwind v4+ tips. Focus on modern features, new utilities, or v4 improvements. Migrating from v3 to v4 is also a good route. Naturally mention Rails UI or component-driven rails development if relevant. Avoid marketing speak. Sound like you're sharing a quick win. Under 200 chars. Examples: 'Container queries in Tailwind v4 are wild. `@container (min-width: 20rem)` for component-based responsive design', 'Tailwind v4 CSS-first approach is so much cleaner. No more config file bloat', 'New `size-*` utilities beat `w-* h-*` for square elements. Much cleaner'",

    ui_insight: "Write a complete tweet about a UI realization like you just had an 'aha' moment. Be specific about user behavior you observed. Naturally mention Rails UI if relevant. Avoid design jargon. Under 200 chars. Example: 'Loading spinners feel slow. Skeleton screens make it seem faster.'",

    building_public: "Write a complete tweet about an honest moment from building your product. Be vulnerable about mistakes or surprises. Naturally mention Rails UI if relevant. Avoid startup clichés. Sound tired but determined. Under 200 chars. Examples: 'Spent 3 days on perfect animations. Users care more about fast load times', 'Thought my feature was brilliant. 5 users tested it. 5 users confused by it', 'Shipped a broken search for Rails UI. Fixed it in 2 hours. Nobody even noticed'",

    rails_8_feature: "Write a complete tweet about Ruby on Rails 8+ features. Be specific about your setup or what changed. Naturally mention Rails UI if relevant. Avoid hype words. Sound like you're recommending to a friend. Under 200 chars. Examples: 'Tried Solid Queue today. Deleted my Redis config. One less thing to worry about', 'Rails 8 auth is stupid simple. Generated working login in 30 seconds', 'Kamal deployed my app faster than I deploy to Heroku. Wild'",

    stimulus_component: "Write a complete tweet about a railsui-stimulus component. Be specific about which component (clipboard, modal, dropdown, toast, etc.) and what problem it solved. Sound like you're recommending to a dev friend. Recommend the components to simplify development with Rails. Under 200 chars. Examples: 'Used the Rails UI modal component. Focus trapping just works.', 'Rails UI clipboard component saved me writing custom copy code', 'Their dropdown handles keyboard nav perfectly. No more custom JS headaches'",

    icon_gem: "Write a complete tweet about the railsui_icon gem like you just discovered something useful. Be specific about heroicons, variants, or custom paths. Sound like you're sharing a quick win. Under 200 chars. Examples: 'railsui_icon gem renders heroicons inline. No more asset hassles', 'Love the variant support in railsui_icon. Solid, outline, mini, micro all work', 'Custom icon paths let me use my own SVGs easily. Game changer for my workflow'"
  }

  AI_RESPONSE_TEMPLATES = {
    rails_tip: [
      "AI_CONTENT_PLACEHOLDER",
      "TIL: AI_CONTENT_PLACEHOLDER",
      "Rails tip: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER 🚀",
      "Just discovered: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER"
    ],
    tailwind_tip: [
      "AI_CONTENT_PLACEHOLDER",
      "CSS tip: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER",
      "Tailwind moment: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER Using this everywhere.",
      "AI_CONTENT_PLACEHOLDER Game changer."
    ],
    ui_insight: [
      "AI_CONTENT_PLACEHOLDER",
      "UX insight: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER",
      "Design realization: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER This changed how I build Rails UI.",
      "AI_CONTENT_PLACEHOLDER"
    ],
    building_public: [
      "AI_CONTENT_PLACEHOLDER",
      "Building Rails UI: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER 🛠️",
      "Solo dev life: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER The reality of shipping products.",
      "AI_CONTENT_PLACEHOLDER Nobody talks about this part."
    ],
    rails_8_feature: [
      "AI_CONTENT_PLACEHOLDER",
      "Rails: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER 🎉",
      "AI_CONTENT_PLACEHOLDER Already using this in Rails UI.",
      "AI_CONTENT_PLACEHOLDER Rails is incredible.",
      "AI_CONTENT_PLACEHOLDER This is exactly what I needed."
    ],
    stimulus_component: [
      "AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER 🎯",
      "AI_CONTENT_PLACEHOLDER Rails UI Stimulus components are solid.",
      "AI_CONTENT_PLACEHOLDER No more custom JS for this.",
      "AI_CONTENT_PLACEHOLDER These components just work."
    ],
    icon_gem: [
      "AI_CONTENT_PLACEHOLDER",
      "Icon tip: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER 🎨",
      "AI_CONTENT_PLACEHOLDER railsui_icon gem is so handy.",
      "AI_CONTENT_PLACEHOLDER Heroicons made easy.",
      "AI_CONTENT_PLACEHOLDER No more SVG hunting."
    ]
  }

  TIMING_FILE = 'posting_schedule.json'
  LOG_FILE = 'posted_content.log'

  def initialize
    x_credentials = {
      api_key: ENV['X_API_KEY'],
      api_key_secret: ENV['X_API_KEY_SECRET'],
      access_token: ENV['X_ACCESS_TOKEN'],
      access_token_secret: ENV['X_ACCESS_TOKEN_SECRET']
    }

    @client = X::Client.new(**x_credentials)
    @timing_data = load_timing_data

    # Initialize OpenAI client
    if ENV['OPENAI_API_KEY']
      @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    else
      puts "⚠️  No OpenAI API key found. Using fallback content only."
      @openai_client = nil
    end
  end

  def load_timing_data
    if File.exist?(TIMING_FILE)
      JSON.parse(File.read(TIMING_FILE))
    else
      {}
    end
  end

  def save_timing_data
    File.write(TIMING_FILE, JSON.pretty_generate(@timing_data))
  end

  def generate_ai_content(content_type)
    return nil unless @openai_client

    begin
      response = @openai_client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: "You are a passionate senior Rails, JavaScript, and Tailwind CSS developer sharing quick thoughts with other devs about new and existing features of the framework. You authored a project called Rails UI, railsui-stimulus, and railsui_icon which all work together to provide real-world professional design for Ruby on Rails developers. Write like you're texting a friend, not writing marketing copy. Use simple words. Be specific about actual problems you solved. For Tailwind tips, focus on v4+ features, modern CSS, new utilities, not old patterns. Avoid: 'game changer', 'leverage', 'seamless', 'streamline', 'elevate', 'boost', 'harness', 'unlock', 'empower', 'robust', 'scalable', 'cutting-edge'. Include frustration or excitement about concrete things. Sound human, not like an AI trying to sound human. No emojis or dumb punctuation. Avoid ':' colon patterns in sentences or titles. Avoid em or en dashses. 200 characters or less."
            },
            {
              role: "user",
              content: AI_PROMPTS[content_type]
            }
          ],
          max_tokens: 120,
          temperature: 1.1,
          frequency_penalty: 0.3,
          presence_penalty: 0.2
        }
      )

      content = response.dig("choices", 0, "message", "content")&.strip

      # Clean up the content
      content = content.gsub(/^["']|["']$/, '') if content # Remove quotes
      content = content.gsub(/\n+/, ' ') if content # Remove newlines

      content
    rescue => e
      puts "⚠️  AI generation failed: #{e.message}"
      nil
    end
  end

  def generate_post
    # Choose content type with weighted selection (favor Rails and UI tips)
    content_type = weighted_content_type_selection

    # Try AI generation first
    ai_content = generate_ai_content(content_type)

    if ai_content && !ai_content.empty?
      # Use AI-generated content directly (it's already a complete tweet)
      formatted_post = ai_content
      source = "AI"
    else
      # Fall back to preset content
      template_group = FALLBACK_TEMPLATES.find { |t| t[:type] == content_type }
      if template_group
        template = template_group[:templates].sample
        content = FALLBACK_CONTENT[content_type].sample
        formatted_post = template.gsub('CONTENT_PLACEHOLDER', content)
        source = "Fallback"
      else
        formatted_post = "Rails 8 is amazing for building modern web apps! 🚀"
        source = "Default"
      end
    end

    # Ensure tweet is under 280 characters
    if formatted_post.length > 280
      # Trim content while preserving the template structure
      excess = formatted_post.length - 277
      lines = formatted_post.split("\n")
      if lines.length > 1
        # Trim the first line (usually the content)
        lines[0] = lines[0][0..-(excess + 4)] + "..."
        formatted_post = lines.join("\n")
      else
        formatted_post = formatted_post[0..276] + "..."
      end
    end

    puts "📝 Generated using: #{source}" if ENV['DEBUG']
    formatted_post
  end

  def weighted_content_type_selection
    # Weight Rails and UI tips more heavily for organic feel
    weighted_types = [
      # Rails tips (40% weight - 20 entries)
      :rails_tip, :rails_tip, :rails_tip, :rails_tip, :rails_tip,
      :rails_tip, :rails_tip, :rails_tip, :rails_tip, :rails_tip,
      :rails_tip, :rails_tip, :rails_tip, :rails_tip, :rails_tip,
      :rails_tip, :rails_tip, :rails_tip, :rails_tip, :rails_tip,

      # UI insights (24% weight - 12 entries)
      :ui_insight, :ui_insight, :ui_insight, :ui_insight, :ui_insight, :ui_insight,
      :ui_insight, :ui_insight, :ui_insight, :ui_insight, :ui_insight, :ui_insight,

      # Tailwind tips (16% weight - 8 entries)
      :tailwind_tip, :tailwind_tip, :tailwind_tip, :tailwind_tip,
      :tailwind_tip, :tailwind_tip, :tailwind_tip, :tailwind_tip,

      # Rails 8 features (10% weight - 5 entries)
      :rails_8_feature, :rails_8_feature, :rails_8_feature, :rails_8_feature, :rails_8_feature,

      # Building public (6% weight - 3 entries)
      :building_public, :building_public, :building_public,

      # Stimulus components (2% weight - 1 entry)
      :stimulus_component,

      # Icon gem (2% weight - 1 entry)
      :icon_gem
    ]

    weighted_types.sample
  end

  def should_post_today?
    return false unless @timing_data['last_posted_at']

    last_posted = Time.parse(@timing_data['last_posted_at'])
    days_since_last_post = (Time.now - last_posted) / (24 * 60 * 60)

    # Post 1-2 times per week (3-7 days apart)
    min_days = 3
    max_days = 7

    return false if days_since_last_post < min_days

    # Increase probability as days pass
    if days_since_last_post >= max_days
      true
    else
      # Random chance increases over time
      probability = (days_since_last_post - min_days) / (max_days - min_days)
      rand < probability
    end
  end

  def time_to_post?
    # First time posting
    return true unless @timing_data['last_posted_at']

    should_post_today?
  end

  def post_to_x
    unless time_to_post?
      puts "⏰ Not time to post yet. Check back later."
      return
    end

    begin
      content = generate_post
      @client.post("tweets", { text: content }.to_json)
      puts "✅ Posted: #{content}"

      # Update timing data
      @timing_data['last_posted_at'] = Time.now.iso8601
      save_timing_data

      # Log to file
      File.open(LOG_FILE, 'a') do |f|
        f.puts "#{Time.now}: #{content}\n"
      end

    rescue X::Error => e
      puts "❌ X API error: #{e.message}"
    rescue => e
      puts "❌ Error posting to X: #{e.message}"
    end
  end

  def demo_run
    puts "🎬 Demo run - showing what would be posted:"
    puts "=" * 50

    content = generate_post
    puts content
    puts "=" * 50
    puts "Character count: #{content.length}/280"
    puts "Time to post: #{time_to_post? ? 'YES' : 'NO'}"
    puts "AI available: #{@openai_client ? 'YES' : 'NO (using fallback content)'}"

    if @timing_data['last_posted_at']
      last_posted = Time.parse(@timing_data['last_posted_at'])
      days_since = (Time.now - last_posted) / (24 * 60 * 60)
      puts "Days since last post: #{days_since.round(1)}"
    else
      puts "No previous posts recorded"
    end
  end

  def status
    puts "📊 Posting Status:"
    puts "=" * 30

    if @timing_data['last_posted_at']
      last_posted = Time.parse(@timing_data['last_posted_at'])
      days_since = (Time.now - last_posted) / (24 * 60 * 60)
      puts "Last posted: #{last_posted.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Days since last post: #{days_since.round(1)}"
      puts "Ready to post: #{time_to_post? ? 'YES' : 'NO'}"
    else
      puts "No previous posts recorded"
      puts "Ready to post: YES (first time)"
    end

    puts "AI available: #{@openai_client ? 'YES' : 'NO (using fallback content)'}"
    puts "Content types: #{AI_RESPONSE_TEMPLATES.keys.join(', ')}"
    puts "Fallback content items: #{FALLBACK_CONTENT.values.flatten.length}"
  end

  def test_ai
    puts "🤖 Testing AI content generation:"
    puts "=" * 40

    AI_PROMPTS.each do |type, prompt|
      puts "\n#{type.to_s.upcase}:"
      puts "Prompt: #{prompt[0..100]}..."

      ai_content = generate_ai_content(type)
      if ai_content
        template = AI_RESPONSE_TEMPLATES[type].sample
        formatted = template.gsub('AI_CONTENT_PLACEHOLDER', ai_content)
        puts "Generated: #{formatted}"
        puts "Length: #{formatted.length}/280"
      else
        puts "❌ Failed to generate AI content"
      end
    end
  end

  def test_distribution
    puts "📊 Testing weighted content distribution:"
    puts "=" * 45

    # Run 1000 selections to get distribution
    results = Hash.new(0)
    1000.times do
      content_type = weighted_content_type_selection
      results[content_type] += 1
    end

    # Calculate percentages and sort by frequency
    total = results.values.sum
    sorted_results = results.sort_by { |k, v| -v }

    puts "Content Type Distribution (1000 samples):"
    puts "-" * 45
    sorted_results.each do |type, count|
      percentage = (count.to_f / total * 100).round(1)
      puts "#{type.to_s.ljust(20)} #{count.to_s.rjust(4)} (#{percentage}%)"
    end

    puts "\nExpected weights:"
    puts "rails_tip:         ~40%"
    puts "ui_insight:        ~25%"
    puts "tailwind_tip:      ~15%"
    puts "rails_8_feature:   ~10%"
    puts "building_public:   ~5%"
    puts "stimulus_component: ~3%"
    puts "icon_gem:          ~2%"
  end
end

# Command line interface
if __FILE__ == $0
  poster = AutoPoster.new

  case ARGV[0]
  when 'demo'
    poster.demo_run
  when 'status'
    poster.status
  when 'post'
    poster.post_to_x
  when 'test-ai'
    poster.test_ai
  when 'test-distribution'
    poster.test_distribution
  else
    puts "Usage:"
    puts "  ruby auto_poster.rb demo              # Show what would be posted"
    puts "  ruby auto_poster.rb status            # Show posting status"
    puts "  ruby auto_poster.rb post              # Post if it's time"
    puts "  ruby auto_poster.rb test-ai           # Test AI generation"
    puts "  ruby auto_poster.rb test-distribution # Test content type distribution"
    puts ""
    puts "Running demo by default..."
    poster.demo_run
  end
end
