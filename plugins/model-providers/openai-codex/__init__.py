"""OpenAI Codex (Responses API) provider profile."""

from hermes_constants import CODEX_BACKEND_BASE_URL
from providers import register_provider
from providers.base import ProviderProfile

openai_codex = ProviderProfile(
    name="openai-codex",
    aliases=("codex", "openai_codex"),
    api_mode="codex_responses",
    env_vars=(),  # OAuth external — no API key
    base_url=CODEX_BACKEND_BASE_URL,
    auth_type="oauth_external",
)

register_provider(openai_codex)
