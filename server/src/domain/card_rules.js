export function cardValue(tag) {
  if (!tag || tag === 'XX' || tag.length < 2) return 0;
  return Number.parseInt(tag.slice(1), 10);
}

export function gameValue(tag) {
  const v = cardValue(tag);
  if (v === 1) return 1;
  if (v >= 11) return 10;
  return v;
}

export function topDiscardValue(throwedCards) {
  if (!throwedCards?.length) return null;
  const top = throwedCards[throwedCards.length - 1];
  const tag = typeof top === 'string' ? top : top.tag;
  return cardValue(tag);
}

export function valuesMatch(a, b) {
  return cardValue(a) === cardValue(b);
}

export function allRevealEnded(participants) {
  return participants.every((p) => p.launchReveal === 'ENDED');
}

export function launchedReveal(participants) {
  return participants.every(
    (p) => p.launchReveal === 'ENDED' || p.launchReveal === 'LAUNCHED',
  );
}
