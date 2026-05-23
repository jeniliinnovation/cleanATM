import { useAuth } from '../context/AuthContext';
import { Clock } from 'lucide-react';

export default function SessionWarning() {
  const { sessionWarning, extendSession } = useAuth();

  if (!sessionWarning) return null;

  return (
    <div className="session-warning">
      <Clock />
      <p>Your session will expire soon due to inactivity</p>
      <button onClick={extendSession}>Stay Logged In</button>
    </div>
  );
}
