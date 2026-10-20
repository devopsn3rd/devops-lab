// Pure functions: easy to unit test and easy to break on purpose for a "failing test" PR.

export function environmentLabel(env) {
  const labels = { devel: 'Development', stage: 'Staging' };
  return labels[env] ?? 'Local';
}

export function greeting(name) {
  const trimmed = (name ?? '').trim();
  return trimmed ? `Hello, ${trimmed}!` : 'Hello, world!';
}

