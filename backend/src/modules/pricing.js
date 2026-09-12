function quote({ rideType = 'movera', distanceMeters = 3000 }) {
  const base = 8900;
  const distance = Math.round((distanceMeters / 1000) * 1200);
  const bookingFee = 500;
  const amountMinor = base + distance + bookingFee;
  return {
    id: `q_${rideType}_${Date.now()}`,
    rideType,
    amountMinor,
    currency: 'SEK',
    expiresInSec: 120,
    breakdown: { base, distance, bookingFee },
  };
}

module.exports = { quote };
