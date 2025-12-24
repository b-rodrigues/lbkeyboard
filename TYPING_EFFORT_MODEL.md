# Typing Effort Model - Implementation and Verification

## Overview

This document describes the Carpalx-inspired typing effort model implemented in `lbkeyboard` and how to verify its correctness.

## Model Components

The typing effort model evaluates keyboard layouts using five weighted components:

### 1. Base Effort (w_base = 3.0)

Each key has an intrinsic difficulty based on three factors:

```cpp
base_effort = row_penalty × finger_penalty × home_distance_penalty
```

**Row Penalties:**
- Number row (row 0): 3.0 (hardest - far reach)
- Top row (row 1): 1.2 (easy upward reach)
- Home row (row 2): 0.5 (easiest - resting position, **2.4x better than top**)
- Bottom row (row 3): 2.0 (harder - curling fingers under)

**Finger Penalties:**
- Pinky (fingers 0, 9): 2.2 (weakest)
- Ring (fingers 1, 8): 1.4
- Middle (fingers 2, 7): 1.0
- Index (fingers 3-6): 0.85 (strongest)

**Home Distance Penalty:**
```
penalty = 1.0 + 0.3 × distance_from_home_column
```
30% penalty for each column away from resting position.

### 2. Same-Finger Bigram Penalty (w_same_finger = 3.0)

Very high penalty when consecutive keys use the same finger:

```cpp
penalty = 3.0 + 2.0 × euclidean_distance(key1, key2)
```

This is extremely inefficient because it requires finger movement instead of hand alternation.

### 3. Same-Hand Bigram Penalty (w_same_hand = 0.5)

Penalty for consecutive keys on the same hand with different fingers:

- **Inward rolls** (index → pinky): 0.5 (comfortable)
- **Outward rolls** (pinky → index): 1.2 (awkward)

Plus **row change penalty** if keys are in different rows.

### 4. Row Change Penalty (w_row_change = 0.5)

Penalty for reaching between rows on the same hand:

- Same row: 0.0
- Adjacent rows: 0.3
- Multiple row jumps: 0.6 × number_of_rows

### 5. **NEW: Same-Hand Trigram Penalty (w_trigram = 0.3)**

Penalty for three consecutive keys on the same hand:

- **Monotonic sequences** (all inward or all outward): 0.5
  - Example: index → middle → ring (smooth roll)
- **Direction-changing sequences**: 2.0 (awkward)
  - Example: index → middle → index (changes direction)

## Total Effort Formula

```
Total Effort = w_base × Σ(base_effort × char_frequency)
             + w_same_finger × Σ(same_finger_penalties)
             + w_same_hand × Σ(same_hand_penalties)
             + w_row_change × Σ(row_change_penalties)
             + w_trigram × Σ(trigram_penalties)
```

## Comparison with Carpalx

### Similarities ✓

| Component | Carpalx | Our Implementation | Match |
|-----------|---------|-------------------|-------|
| Base effort | ✓ Row, finger, distance | ✓ Row, finger, distance | ✓ |
| Path penalties | ✓ Same-finger high cost | ✓ Same-finger bigrams | ✓ |
| Hand penalties | ✓ Same-hand sequences | ✓ Same-hand with rolls | ✓ |
| Stroke path | ✓ Row jumps | ✓ Row changes + **trigrams** | ✓ |
| Configurability | ✓ Weight parameters | ✓ effort_weights list | ✓ |

### Differences

**Carpalx:**
- Uses **multiplicative** nested formula: `b = b_h × b_i × (1 + k_d × d_i × (1 + k_r × r_i))`
- More complex interaction terms
- Stroke path based on triad categories

**Our Implementation:**
- Uses **additive** weighted sum (simpler, more interpretable)
- Direct penalty calculations
- Explicit trigram tracking for direction changes

**Result:** Both approaches capture the same biomechanical principles, but our implementation is more straightforward and easier to tune.

## Verification Tests

### Test 1: Component Verification

Run the test script to verify all components are active:

```r
source("test_typing_effort.R")
```

Expected output:
- ✓ All 5 components contribute to total effort
- ✓ Base effort should be 40-60% of total (most common letters on good positions)
- ✓ Same-finger bigrams should be heavily penalized
- ✓ Trigrams should be detected and penalized

### Test 2: QWERTY Analysis

Compare with carpalx QWERTY statistics:

**Expected patterns:**
- Home row usage: ~30-40% (ASDFGHJKL)
- Top row usage: ~50-55% (QWERTYUIOP)
- Same-finger bigrams: Relatively low (~5-10%)
- Hand alternation: High (~40-50%)

### Test 3: Layout Comparison

QWERTY should perform moderately (carpalx ranks it middle-tier):
- Better than: Random layouts, TNWMLC (worst)
- Worse than: Dvorak, Colemak, QGMLWY (optimized)

### Test 4: Optimization Convergence

When optimizing a layout:
- Effort should **decrease** over generations
- Best effort should converge to a stable value
- Optimized layouts should show:
  - More home row usage
  - Fewer same-finger bigrams
  - Better hand alternation

## Key Metrics to Verify

### 1. Effort Breakdown (percentage of total)

Typical ranges for English text:

| Component | Expected % | Notes |
|-----------|-----------|-------|
| Base effort | 40-60% | Most letters typed, base cost |
| Same-finger | 15-30% | Should be significant penalty |
| Same-hand | 10-20% | Moderate penalty |
| Row change | 5-15% | Varies by layout |
| Trigram | 3-8% | New component |

### 2. Typing Statistics

For QWERTY on English text:

| Metric | Expected Value |
|--------|---------------|
| Same-finger bigrams | 5-10% of bigrams |
| Hand alternations | 40-50% of bigrams |
| Home row usage | 30-40% of chars |

### 3. Optimization Improvement

When optimizing for English:
- Should achieve **15-30% improvement** over QWERTY
- Optimized layout should have **more home row letters** (50-70%)
- Should have **fewer same-finger bigrams** (<5%)

## Example Test Output

```r
library(lbkeyboard)

# Load test data
data(english)

# Analyze QWERTY
qwerty <- create_default_keyboard()
breakdown <- calculate_layout_effort(
  keyboard = qwerty,
  text_samples = english,
  breakdown = TRUE
)

# Expected results:
# - total_effort: ~2000-5000 (depends on text length)
# - same_finger_bigrams: ~100-300
# - hand_alternations: ~800-1500
# - same_hand_trigrams: ~200-500
```

## Validation Checklist

- [ ] All 5 effort components contribute to total effort
- [ ] Zeroing a component weight reduces total effort
- [ ] Same-finger bigrams are heavily penalized (high effort)
- [ ] Trigrams are detected and counted correctly
- [ ] Home row keys have lower base effort than top/bottom rows
- [ ] Index fingers have lower penalty than pinkies
- [ ] Random layouts score worse than QWERTY
- [ ] Optimization improves effort over generations
- [ ] Effort breakdown percentages are reasonable
- [ ] Model is sensitive to weight parameter changes

## Troubleshooting

### Issue: All effort is from one component

**Cause:** Weights are unbalanced
**Fix:** Use default weights or adjust to balance contributions

### Issue: Optimization doesn't improve

**Cause:** May be stuck in local minimum or weights favor conflicting goals
**Fix:** Try different random seeds, adjust weights, increase population size

### Issue: Trigram count is zero

**Cause:** Text sample too short or no same-hand sequences
**Fix:** Use longer text with natural language patterns

### Issue: Results differ from carpalx

**Expected:** Our model is simpler (additive vs multiplicative)
**Normal:** Absolute values will differ, but **relative rankings** should match

## Mathematical Correctness

The model is mathematically sound because:

1. **All terms are non-negative** → effort always ≥ 0
2. **Monotonic in penalties** → more difficulty = more effort
3. **Scales with text length** → longer text = proportionally more effort
4. **Additive components** → easy to interpret and tune
5. **Configurable weights** → can adapt to different languages/preferences

## Conclusion

The typing effort model is a **simplified but faithful** implementation of the carpalx approach:

- ✅ Captures all major biomechanical factors
- ✅ Includes trigram penalties (enhancement over basic carpalx)
- ✅ Produces reasonable and interpretable results
- ✅ Suitable for keyboard layout optimization
- ✅ More accessible than original carpalx (simpler formula)

The model should produce layouts with similar characteristics to carpalx-optimized layouts (home row emphasis, hand alternation, minimal same-finger).
