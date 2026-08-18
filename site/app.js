(() => {
  const parts = location.pathname.split('/').filter(Boolean);
  const onGitHubPages = location.hostname.endsWith('.github.io') && parts.length > 0;
  const owner = onGitHubPages ? location.hostname.split('.')[0] : 'OWNER';
  const repo = onGitHubPages ? parts[0] : 'ai-monitor';
  const repoURL = `https://github.com/${owner}/${repo}`;
  if (owner !== 'OWNER') {
    document.querySelectorAll('[data-repo-link]').forEach((link) => { link.href = repoURL; });
    document.querySelectorAll('[data-repo-path]').forEach((link) => { link.href = `${repoURL}${link.dataset.repoPath}`; });
    document.querySelectorAll('[data-download-link]').forEach((link) => { link.href = `${repoURL}/releases/latest/download/AI-Monitor.dmg`; });
  }
})();
