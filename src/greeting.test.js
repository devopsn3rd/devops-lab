import { environmentLabel, greeting } from './greeting.js';

describe('environmentLabel', () => {
  test('maps known environments', () => {
    expect(environmentLabel('devel')).toBe('Development');
    expect(environmentLabel('stage')).toBe('Staging');
  });

  test('falls back to Local', () => {
    expect(environmentLabel(undefined)).toBe('Local');
  });
});

describe('greeting', () => {
  test('greets by name', () => {
    expect(greeting('Luis')).toBe('Hello, Luis!');
  });

  test('handles empty input', () => {
    expect(greeting('   ')).toBe('Hello, world!');
  });
});
