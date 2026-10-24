{...}: {
  # This device uses an ANTHROPIC_API_KEY (export it in the shell, or run
  # `pi` then /login) instead of the shared openrouter default.
  flake.modules.homeManager-thinkpad.ai-agents = {...}: {
    aiAgents.pi.settingsFile = "settings.thinkpad.json";
  };
}
