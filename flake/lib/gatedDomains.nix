# Domains routed via the US-residential egress path (charon allowlist == proxyRouter gate).
{
  flake.lib.gatedDomains = [
    # Residential
    "tello.com"
    "t-mobile.com"
    "paypal.com"
    "paypalobjects.com"
    "tradingview.com"
    "interactivebrokers.com"
    "openrouter.ai"

    # OpenAI (github:blackmatrix7/ios_rule_script Surge/OpenAI/OpenAI.list, 2025-06-06)
    "browser-intake-datadoghq.com"
    "chat.openai.com.cdn.cloudflare.net"
    "openai-api.arkoselabs.com"
    "openaicom-api-bdcpf8c6d2e9atf6.z01.azurefd.net"
    "openaicomproductionae4b.blob.core.windows.net"
    "production-openaicom-storage.azureedge.net"
    "static.cloudflareinsights.com"
    "ai.com"
    "algolia.net"
    "api.statsig.com"
    "auth0.com"
    "chatgpt.com"
    "chatgpt.livekit.cloud"
    "client-api.arkoselabs.com"
    "events.statsigapi.net"
    "featuregates.org"
    "host.livekit.cloud"
    "identrust.com"
    "intercom.io"
    "intercomcdn.com"
    "launchdarkly.com"
    "oaistatic.com"
    "oaiusercontent.com"
    "observeit.net"
    "openai.com"
    "openaiapi-site.azureedge.net"
    "openaicom.imgix.net"
    "segment.io"
    "sentry.io"
    "stripe.com"
    "turn.livekit.cloud"

    # Anthropic / Claude
    "anthropic.com"
    "claude.ai"
    "claude.com"
    "cdn.usefathom.com"
    "datadoghq.com"
    "deepwiki.com"

    # Google / GitHub
    "github.com"
    "google.com"
    "google.com.hk"
    "googleapis.com"

    # Cloudflare
    "cloudflare.com"
    "cloudflare.net"

    # Misc
    "ycombinator.com"
    "acm.org"
    "archive.org"
  ];
}
