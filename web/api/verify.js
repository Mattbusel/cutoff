// Confirms a Checkout session was paid, so the browser can unlock Pro.
module.exports = async (req, res) => {
  const id = String((req.query && req.query.session_id) || '');
  if (!/^cs_(live|test)_[A-Za-z0-9]+$/.test(id)) { res.status(200).json({ paid: false }); return; }
  const r = await fetch('https://api.stripe.com/v1/checkout/sessions/' + id, {
    headers: { Authorization: 'Bearer ' + process.env.STRIPE_SECRET_KEY }
  });
  const j = await r.json();
  res.status(200).json({ paid: r.ok && j.payment_status === 'paid' });
};
