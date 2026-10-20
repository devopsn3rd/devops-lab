import { useState } from 'react';
import PropTypes from 'prop-types';
import { environmentLabel, greeting } from './greeting.js';

export default function App({ environment }) {
  const [clicks, setClicks] = useState(0);

  return (
    <main>
      <span className="badge">{environmentLabel(environment)}</span>
      <h1>{greeting('DevOps Lab')}</h1>
      <p>Static React app served from S3 through CloudFront, deployed by Terraform, adding a Feature.</p>
      <button type="button" onClick={() => setClicks((c) => c + 1)}>
        Clicked {clicks} times
      </button>
    </main>
  );
}

App.propTypes = {
  environment: PropTypes.string,
};
