export function connection(connectionString) {
  const url = new URL(connectionString);
  const local = ['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname);
  const tls = !local || process.env.NODE_ENV === 'production';
  if (tls) {
    for (const key of ['ssl','sslmode','sslrootcert','sslcert','sslkey']) url.searchParams.delete(key);
  }
  return {
    connectionString: url.toString(),
    ...(tls && {ssl: {rejectUnauthorized: true, ca: process.env.DATABASE_CA_CERT?.replace(/\\n/g, '\n')}}),
  };
}
