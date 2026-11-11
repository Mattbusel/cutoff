// Creates a Stripe Checkout session for Cutoff Pro (web), $2.99 one time.
module.exports = async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'POST only' }); return; }
  const origin = 'https://' + (req.headers['x-forwarded-host'] || req.headers.host);
  const body = new URLSearchParams({
    mode: 'payment',
    'line_items[0][quantity]': '1',
    'line_items[0][price_data][currency]': 'usd',
    'line_items[0][price_data][unit_amount]': '299',
    'line_items[0][price_data][product_data][name]': 'Cutoff Pro (web)',
    'line_items[0][price_data][product_data][description]': 'Your half-life and sleep line, your own drinks, and your week. One payment.',
    success_url: origin + '/?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: origin + '/',
    allow_promotion_codes: 'true'
  });
  const r = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + process.env.STRIPE_SECRET_KEY, 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });
  const j = await r.json();
  if (!r.ok) { res.status(502).json({ error: 'stripe' }); return; }
  res.status(200).json({ url: j.url });
};
