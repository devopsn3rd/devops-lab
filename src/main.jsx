import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App environment={import.meta.env.VITE_APP_ENV} />
  </StrictMode>,
);
