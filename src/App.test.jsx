import { render, screen, fireEvent } from '@testing-library/react';
import App from './App.jsx';

test('renders the environment badge', () => {
  render(<App environment="stage" />);
  expect(screen.getByText('Staging')).toBeInTheDocument();
});

test('counts clicks', () => {
  render(<App environment="devel" />);
  fireEvent.click(screen.getByRole('button'));
  expect(screen.getByRole('button')).toHaveTextContent('Clicked 1 times');
});
