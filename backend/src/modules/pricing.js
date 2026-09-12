const pricesKr = {
  movera: 259,
  comfort: 339,
  premium: 369,
  priority: 289,
  xl: 399,
  electric: 259,
  pet: 279,
};

function quote({ rideType = 'movera', distanceMeters = 3000 }) {
  const kr = pricesKr[rideType] || 259;
  const amountMinor = kr * 100;
  return {
    id: `q_${rideType}_${Date.now()}`,
    quoteId: `q_${rideType}_${Date.now()}`,
    rideType,
    totalMinor: amountMinor,
    amountMinor,
    currency: 'SEK',
    expiresInSec: 120,
    breakdown: { baseMinor: amountMinor, distanceMinor: 0, timeMinor: 0, bookingFeeMinor: 0 },
    signedPayload: 'mock-api',
  };
}

module.exports = { quote, pricesKr };
