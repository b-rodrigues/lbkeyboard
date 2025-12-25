// genetic_keyboard.cpp
// Genetic algorithm for keyboard layout optimization
// Effort model inspired by Carpalx (http://mkweb.bcgsc.ca/carpalx/)

#include <Rcpp.h>
#include <algorithm>
#include <random>
#include <unordered_map>
#include <cmath>
#include <vector>
#include <string>

using namespace Rcpp;

// -----------------------------------------------------------------
// FINGER ASSIGNMENT AND KEY POSITION DATA
// -----------------------------------------------------------------

// Finger indices: 0-4 = left pinky to thumb, 5-9 = right thumb to pinky
// For standard touch typing on QWERTY-like layouts
// Row 0 = number row, Row 1 = top letter row, Row 2 = home row, Row 3 = bottom row

// Key position structure
struct KeyPosition {
  double x;
  double y;
  int row;       // 0-3 (number row to bottom row for typeable keys)
  int column;    // position in row
  int finger;    // 0-9 (left pinky to right pinky)
  int hand;      // 0 = left, 1 = right
};

// Default finger assignments for standard ISO layout columns
// This maps column position to finger (for rows 1-3: top, home, bottom letter rows)
// NOTE: This is a fallback for when x_mid is not available
int get_finger_for_column(int col) {
  // Left hand: 0-4
  // 0: Pinky (Q, A, Z)
  // 1: Ring (W, S, X)
  // 2: Middle (E, D, C)
  // 3: Index (R, F, V)
  // 4: Index (T, G, B)

  // Right hand: 5-9+
  // 5: Index (Y, H, N)
  // 6: Index (U, J, M)
  // 7: Middle (I, K)
  // 8: Ring (O, L)
  // 9+: Pinky (P)

  if (col == 0) return 0;       // left pinky
  if (col == 1) return 1;       // left ring
  if (col == 2) return 2;       // left middle
  if (col <= 4) return 3;       // left index (cols 3, 4)

  if (col <= 6) return 6;       // right index (cols 5, 6)
  if (col == 7) return 7;       // right middle
  if (col == 8) return 8;       // right ring
  return 9;                     // right pinky
}

// BETTER: Calculate finger based on x_mid position (works for any layout)
// Assumes standard touch typing: hands split at keyboard center
int get_finger_for_x_position(double x_mid, double min_x, double max_x) {
  // Find keyboard center
  double center = (min_x + max_x) / 2.0;
  double width = max_x - min_x;

  // Normalize position relative to center
  double rel_pos = (x_mid - center) / (width / 2.0);  // -1 to +1

  // Left hand (negative): -1.0 to 0.0
  if (rel_pos < 0) {
    double abs_pos = -rel_pos;  // 0 to 1.0
    if (abs_pos > 0.75) return 0;  // far left = left pinky
    if (abs_pos > 0.50) return 1;  // left ring
    if (abs_pos > 0.25) return 2;  // left middle
    return 3;                       // left index
  }
  // Right hand (positive): 0.0 to 1.0
  else {
    if (rel_pos < 0.25) return 6;  // right index
    if (rel_pos < 0.50) return 7;  // right middle
    if (rel_pos < 0.75) return 8;  // right ring
    return 9;                       // right pinky
  }
}

int get_hand_for_finger(int finger) {
  return (finger <= 4) ? 0 : 1;
}

// -----------------------------------------------------------------
// CARPALX-INSPIRED EFFORT MODEL
// -----------------------------------------------------------------

// Base effort for each key position
// Incorporates: row penalties, finger strength, and distance from home position
// Lower values = easier to type
// Home row is row 2 (index 2), fingers rest on home position

// Row penalties (relative difficulty of reaching each row)
// Row 0 = number row (hardest), Row 1 = top, Row 2 = home (easiest), Row 3 = bottom
// Home row should be distinctly advantaged
double row_penalty(int row) {
  switch(row) {
    case 0: return 3.0;   // Number row - far reach (hardest)
    case 1: return 1.2;   // Top row - easy reach upward
    case 2: return 0.5;   // Home row - MUCH better (2.4x better than top)
    case 3: return 2.0;   // Bottom row - harder (curling fingers under)
    default: return 2.5;
  }
}

// Finger strength/dexterity penalty (weaker fingers = higher penalty)
double finger_penalty(int finger) {
  // Pinkies are weakest, index fingers strongest
  // Left: 0(P), 1(R), 2(M), 3(I), 4(I)
  // Right: 5(I), 6(I), 7(M), 8(R), 9(P)
  
  if (finger == 0 || finger == 9) return 2.2;  // Pinky (weakest)
  if (finger == 1 || finger == 8) return 1.4;  // Ring
  if (finger == 2 || finger == 7) return 1.0;  // Middle
  if (finger >= 3 && finger <= 6) return 0.85; // Index (strongest, preferred)
  
  return 1.5; // Fallback
}

// Distance from home position penalty (LEGACY - column-based)
// Kept for compatibility but should use x-position version
double home_distance_penalty(int col, int finger) {
  int home_col;
  switch(finger) {
    case 0: home_col = 0; break;
    case 1: home_col = 1; break;
    case 2: home_col = 2; break;
    case 3: home_col = 3; break;
    case 6: home_col = 6; break;
    case 7: home_col = 7; break;
    case 8: home_col = 8; break;
    case 9: home_col = 9; break;
    default: home_col = col;
  }
  double dist = std::abs(col - home_col);
  return 1.0 + 0.3 * dist;
}

// Distance from home position penalty (x-position based - layout independent!)
// Keys in the center of a finger's zone are easier than keys at the edges
double home_distance_penalty_x(double x_mid, int finger, double min_x, double max_x) {
  double center = (min_x + max_x) / 2.0;
  double width = max_x - min_x;
  double rel_pos = (x_mid - center) / (width / 2.0);  // -1 to +1

  // Define home position (resting position) for each finger
  // This is the center of each finger's zone
  double home_pos;
  switch(finger) {
    case 0: home_pos = -0.875; break;  // left pinky (far left)
    case 1: home_pos = -0.625; break;  // left ring
    case 2: home_pos = -0.375; break;  // left middle
    case 3: home_pos = -0.125; break;  // left index
    case 6: home_pos =  0.125; break;  // right index
    case 7: home_pos =  0.375; break;  // right middle
    case 8: home_pos =  0.625; break;  // right ring
    case 9: home_pos =  0.875; break;  // right pinky (far right)
    default: home_pos = rel_pos; break;
  }

  // Calculate distance from home position within finger's zone
  double dist = std::abs(rel_pos - home_pos);

  // Normalize: dist of 0.25 = 1 finger zone away
  // This roughly corresponds to moving 1 "column" in the old system
  double normalized_dist = dist / 0.25;

  return 1.0 + 0.3 * normalized_dist;  // 30% penalty per zone away from home
}

// Base effort for a single key (LEGACY - column-based)
double base_key_effort(int row, int col, int finger) {
  return row_penalty(row) * finger_penalty(finger) * home_distance_penalty(col, finger);
}

// Base effort for a single key (x-position based - USE THIS!)
double base_key_effort_x(int row, double x_mid, int finger, double min_x, double max_x) {
  return row_penalty(row) * finger_penalty(finger) * home_distance_penalty_x(x_mid, finger, min_x, max_x);
}

// -----------------------------------------------------------------
// BIGRAM (SAME-HAND, SAME-FINGER) PENALTIES
// -----------------------------------------------------------------

// Penalty for typing two keys in sequence with the same finger
double same_finger_penalty(int row1, int row2, int col1, int col2) {
  // Same finger bigrams are very inefficient
  // Penalty scales with distance between keys
  double row_dist = std::abs(row1 - row2);
  double col_dist = std::abs(col1 - col2);
  double dist = std::sqrt(row_dist * row_dist + col_dist * col_dist);
  return 3.0 + 2.0 * dist;  // Base penalty plus distance
}

// Penalty for typing two keys with the same hand
// Hand alternation is preferred
double same_hand_penalty(int row1, int row2, int col1, int col2, int finger1, int finger2) {
  // If same finger, that's handled separately
  if (finger1 == finger2) return 0.0;

  // Same hand, different fingers
  // Inward rolls (index to pinky) are easier than outward rolls
  bool is_left = (finger1 <= 4);
  int dir = finger2 - finger1;

  // Inward roll on left hand = decreasing finger, on right = increasing
  bool is_inward = (is_left && dir < 0) || (!is_left && dir > 0);

  if (is_inward) {
    return 0.5;  // Small penalty for inward roll (comfortable)
  } else {
    return 1.2;  // Larger penalty for outward roll
  }
}

// Row change penalty (reaching between rows on same hand)
double row_change_penalty(int row1, int row2) {
  int diff = std::abs(row1 - row2);
  if (diff == 0) return 0.0;
  if (diff == 1) return 0.3;
  return 0.6 * diff;  // Larger jumps are harder
}

// -----------------------------------------------------------------
// TRIGRAM PENALTIES (FOR SAME-HAND SEQUENCES)
// -----------------------------------------------------------------

// Penalty for three consecutive keys on same hand
double same_hand_trigram_penalty(int finger1, int finger2, int finger3, bool is_left) {
  // Monotonic sequences (all inward or all outward) are acceptable
  // Mixed direction sequences are awkward
  int dir1 = finger2 - finger1;
  int dir2 = finger3 - finger2;

  if ((dir1 > 0 && dir2 > 0) || (dir1 < 0 && dir2 < 0)) {
    // Monotonic - relatively comfortable
    return 0.5;
  } else {
    // Direction change - awkward
    return 2.0;
  }
}

// -----------------------------------------------------------------
// LAYOUT REPRESENTATION AND MANIPULATION
// -----------------------------------------------------------------

// A layout is represented as a permutation of characters
// Layout maps character -> position index
// Position index maps to physical key location

class KeyboardLayout {
public:
  std::vector<char> keys;           // Character at each position
  std::vector<KeyPosition> positions; // Physical position info
  int n_keys;

  KeyboardLayout() : n_keys(0) {}

  KeyboardLayout(const std::vector<char>& k, const std::vector<KeyPosition>& p)
    : keys(k), positions(p), n_keys(k.size()) {}

  // Find position index for a character
  int find_key(char c) const {
    for (int i = 0; i < n_keys; i++) {
      if (keys[i] == c) return i;
    }
    return -1;  // Not found
  }

  // Swap two keys in the layout
  void swap_keys(int i, int j) {
    std::swap(keys[i], keys[j]);
  }

  // Get a copy with swapped keys
  KeyboardLayout with_swap(int i, int j) const {
    KeyboardLayout copy = *this;
    copy.swap_keys(i, j);
    return copy;
  }
};

// -----------------------------------------------------------------
// EFFORT CALCULATION
// -----------------------------------------------------------------

// Calculate total typing effort for a text sample given a layout
// Internal function - not exported (std::vector<char> not supported by Rcpp)
double calculate_effort(
    const std::vector<char>& layout_keys,
    const std::vector<double>& pos_x,
    const std::vector<double>& pos_y,
    const std::vector<int>& pos_row,
    const std::vector<int>& pos_col,
    const std::string& text,
    const std::vector<double>& char_freq,
    const std::vector<char>& char_list,
    double w_base = 1.0,
    double w_same_finger = 3.0,
    double w_same_hand = 1.0,
    double w_row_change = 0.5,
    double w_trigram = 0.3
) {
  int n = layout_keys.size();

  // Build character -> position mapping
  std::unordered_map<char, int> char_to_pos;
  for (int i = 0; i < n; i++) {
    char_to_pos[layout_keys[i]] = i;
    // Also add uppercase version
    if (layout_keys[i] >= 'a' && layout_keys[i] <= 'z') {
      char_to_pos[layout_keys[i] - 32] = i;  // uppercase maps to same position
    }
  }

  // Calculate finger assignments based on x position (works for any layout!)
  // Find min/max x to determine keyboard bounds
  double min_x = *std::min_element(pos_x.begin(), pos_x.end());
  double max_x = *std::max_element(pos_x.begin(), pos_x.end());

  std::vector<int> fingers(n);
  std::vector<int> hands(n);
  for (int i = 0; i < n; i++) {
    // Use x position for layout-independent finger assignment
    fingers[i] = get_finger_for_x_position(pos_x[i], min_x, max_x);
    hands[i] = get_hand_for_finger(fingers[i]);
  }

  double total_effort = 0.0;
  
  // Get text length for scaling base effort properly
  // (char_freq are proportions 0-1, but bigrams count per-character)
  double text_len = static_cast<double>(text.length());

  // Base effort (weighted by character frequency)
  // Scale by text length so base effort is comparable to bigram effort
  for (size_t i = 0; i < char_list.size(); i++) {
    char c = char_list[i];
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end()) {
      // Try lowercase
      if (c >= 'A' && c <= 'Z') {
        it = char_to_pos.find(c + 32);
      }
    }
    if (it != char_to_pos.end()) {
      int pos = it->second;
      // Use x-position-based effort (layout-independent!)
      double base = base_key_effort_x(pos_row[pos], pos_x[pos], fingers[pos], min_x, max_x);
      // Multiply by text_len to scale properly
      total_effort += w_base * base * char_freq[i] * text_len;
    }
  }

  // Bigram and trigram effort (process text for consecutive pairs and triples)
  int prev_prev_pos = -1;
  int prev_pos = -1;
  for (size_t i = 0; i < text.length(); i++) {
    char c = std::tolower(text[i]);
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end()) continue;

    int curr_pos = it->second;

    // Process bigrams
    if (prev_pos >= 0) {
      int finger1 = fingers[prev_pos];
      int finger2 = fingers[curr_pos];
      int hand1 = hands[prev_pos];
      int hand2 = hands[curr_pos];

      // Same finger penalty
      if (finger1 == finger2 && prev_pos != curr_pos) {
        total_effort += w_same_finger * same_finger_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos]
        );
      }
      // Same hand penalty
      else if (hand1 == hand2) {
        total_effort += w_same_hand * same_hand_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos],
          finger1, finger2
        );
        total_effort += w_row_change * row_change_penalty(
          pos_row[prev_pos], pos_row[curr_pos]
        );
      }
      // Hand alternation (preferred - no penalty)
    }

    // Process trigrams (three consecutive keys on same hand)
    if (prev_prev_pos >= 0 && prev_pos >= 0) {
      int finger0 = fingers[prev_prev_pos];
      int finger1 = fingers[prev_pos];
      int finger2 = fingers[curr_pos];
      int hand0 = hands[prev_prev_pos];
      int hand1 = hands[prev_pos];
      int hand2 = hands[curr_pos];

      // Only penalize if all three keys are on the same hand
      if (hand0 == hand1 && hand1 == hand2) {
        bool is_left = (hand0 == 0);
        total_effort += w_trigram * same_hand_trigram_penalty(
          finger0, finger1, finger2, is_left
        );
      }
    }

    prev_prev_pos = prev_pos;
    prev_pos = curr_pos;
  }

  return total_effort;
}

// -----------------------------------------------------------------
// RULE PENALTY CALCULATIONS
// -----------------------------------------------------------------

// Calculate penalties from soft preference rules
double calculate_rule_penalties(
    const std::vector<char>& layout,
    const std::vector<int>& pos_row,
    const std::vector<int>& pos_col,
    const std::vector<double>& char_freq,
    const std::vector<char>& char_list,
    // Hand preference rule - now uses character keys, not indices
    const std::vector<char>& hand_pref_keys,
    const std::vector<int>& hand_pref_targets,
    double hand_pref_weight,
    // Row preference rule - now uses character keys, not indices
    const std::vector<char>& row_pref_keys,
    const std::vector<int>& row_pref_targets,
    double row_pref_weight,
    // Balance hands rule
    double balance_target,
    double balance_weight
) {
  double penalty = 0.0;
  int n = layout.size();

  // Build character -> position mapping for the current layout
  std::unordered_map<char, int> char_to_pos;
  for (int i = 0; i < n; i++) {
    char_to_pos[layout[i]] = i;
    // If lowercase, add uppercase
    if (layout[i] >= 'a' && layout[i] <= 'z') {
      char_to_pos[layout[i] - 32] = i;
    }
    // If uppercase, add lowercase
    else if (layout[i] >= 'A' && layout[i] <= 'Z') {
      char_to_pos[layout[i] + 32] = i;
    }
  }

  // Calculate hand for each position (based on column)
  // Columns 0-4 = left hand, 5+ = right hand
  auto get_hand = [&](int pos) -> int {
    int col = pos_col[pos];
    if (col <= 4) return 0;  // left
    if (col >= 5) return 1;  // right
    return 0;
  };

  // Hand preference penalties - look up each key character directly
  if (hand_pref_weight > 0.0 && !hand_pref_keys.empty()) {
    for (size_t i = 0; i < hand_pref_keys.size(); i++) {
      char key = std::tolower(hand_pref_keys[i]);
      auto it = char_to_pos.find(key);
      if (it != char_to_pos.end()) {
        int actual_hand = get_hand(it->second);
        int target_hand = hand_pref_targets[i];
        if (actual_hand != target_hand) {
          penalty += hand_pref_weight;
        }
      }
    }
  }

  // Row preference penalties - look up each key character directly
  if (row_pref_weight > 0.0 && !row_pref_keys.empty()) {
    for (size_t i = 0; i < row_pref_keys.size(); i++) {
      char key = std::tolower(row_pref_keys[i]);
      auto it = char_to_pos.find(key);
      if (it != char_to_pos.end()) {
        int actual_row = pos_row[it->second];
        int target_row = row_pref_targets[i];
        if (actual_row != target_row) {
          // Penalty proportional to row distance
          penalty += row_pref_weight * std::abs(actual_row - target_row);
        }
      }
    }
  }

  // Hand balance penalty
  if (balance_weight > 0.0) {
    double left_load = 0.0;
    double total_load = 0.0;

    for (size_t i = 0; i < char_list.size(); i++) {
      char c = std::tolower(char_list[i]);
      auto it = char_to_pos.find(c);
      if (it != char_to_pos.end()) {
        int hand = get_hand(it->second);
        double freq = char_freq[i];
        total_load += freq;
        if (hand == 0) {
          left_load += freq;
        }
      }
    }

    if (total_load > 0.0) {
      double actual_balance = left_load / total_load;
      double imbalance = std::abs(actual_balance - balance_target);
      // Quadratic penalty for imbalance
      penalty += balance_weight * imbalance * imbalance * 100.0;
    }
  }

  return penalty;
}

// Calculate effort including rule penalties
double calculate_effort_with_rules(
    const std::vector<char>& layout_keys,
    const std::vector<double>& pos_x,
    const std::vector<double>& pos_y,
    const std::vector<int>& pos_row,
    const std::vector<int>& pos_col,
    const std::string& text,
    const std::vector<double>& char_freq,
    const std::vector<char>& char_list,
    double w_base,
    double w_same_finger,
    double w_same_hand,
    double w_row_change,
    double w_trigram,
    // Rule parameters - now use character vectors for keys
    const std::vector<char>& hand_pref_keys,
    const std::vector<int>& hand_pref_targets,
    double hand_pref_weight,
    const std::vector<char>& row_pref_keys,
    const std::vector<int>& row_pref_targets,
    double row_pref_weight,
    double balance_target,
    double balance_weight
) {
  double base_effort = calculate_effort(
    layout_keys, pos_x, pos_y, pos_row, pos_col,
    text, char_freq, char_list,
    w_base, w_same_finger, w_same_hand, w_row_change, w_trigram
  );

  double rule_penalty = calculate_rule_penalties(
    layout_keys, pos_row, pos_col, char_freq, char_list,
    hand_pref_keys, hand_pref_targets, hand_pref_weight,
    row_pref_keys, row_pref_targets, row_pref_weight,
    balance_target, balance_weight
  );

  return base_effort + rule_penalty;
}

// -----------------------------------------------------------------
// UTILITY FUNCTIONS
// -----------------------------------------------------------------

// Calculate effort for a single layout (for comparison)
// [[Rcpp::export]]
double layout_effort(
    CharacterVector layout,
    NumericVector pos_x,
    NumericVector pos_y,
    IntegerVector pos_row,
    IntegerVector pos_col,
    CharacterVector text_samples,
    NumericVector char_freq,
    CharacterVector char_list,
    double w_base = 1.0,
    double w_same_finger = 3.0,
    double w_same_hand = 1.0,
    double w_row_change = 0.5,
    double w_trigram = 0.3
) {
  int n = layout.size();
  std::vector<char> layout_keys(n);
  for (int i = 0; i < n; i++) {
    std::string s = Rcpp::as<std::string>(layout[i]);
    layout_keys[i] = s.empty() ? ' ' : s[0];
  }

  std::vector<double> px = Rcpp::as<std::vector<double>>(pos_x);
  std::vector<double> py = Rcpp::as<std::vector<double>>(pos_y);
  std::vector<int> pr = Rcpp::as<std::vector<int>>(pos_row);
  std::vector<int> pc = Rcpp::as<std::vector<int>>(pos_col);

  std::string combined_text;
  for (int i = 0; i < text_samples.size(); i++) {
    combined_text += Rcpp::as<std::string>(text_samples[i]) + " ";
  }

  std::vector<double> cf = Rcpp::as<std::vector<double>>(char_freq);
  std::vector<char> cl(char_list.size());
  for (int i = 0; i < char_list.size(); i++) {
    std::string s = Rcpp::as<std::string>(char_list[i]);
    cl[i] = s.empty() ? ' ' : s[0];
  }

  return calculate_effort(
    layout_keys, px, py, pr, pc,
    combined_text, cf, cl,
    w_base, w_same_finger, w_same_hand, w_row_change, w_trigram
  );
}

// Get detailed effort breakdown
// [[Rcpp::export]]
List effort_breakdown(
    CharacterVector layout,
    NumericVector pos_x,
    NumericVector pos_y,
    IntegerVector pos_row,
    IntegerVector pos_col,
    CharacterVector text_samples,
    NumericVector char_freq,
    CharacterVector char_list
) {
  int n = layout.size();
  std::vector<char> layout_keys(n);
  for (int i = 0; i < n; i++) {
    std::string s = Rcpp::as<std::string>(layout[i]);
    layout_keys[i] = s.empty() ? ' ' : s[0];
  }

  std::vector<double> px = Rcpp::as<std::vector<double>>(pos_x);
  std::vector<double> py = Rcpp::as<std::vector<double>>(pos_y);
  std::vector<int> pr = Rcpp::as<std::vector<int>>(pos_row);
  std::vector<int> pc = Rcpp::as<std::vector<int>>(pos_col);

  std::string combined_text;
  for (int i = 0; i < text_samples.size(); i++) {
    combined_text += Rcpp::as<std::string>(text_samples[i]) + " ";
  }

  std::vector<double> cf = Rcpp::as<std::vector<double>>(char_freq);
  std::vector<char> cl(char_list.size());
  for (int i = 0; i < char_list.size(); i++) {
    std::string s = Rcpp::as<std::string>(char_list[i]);
    cl[i] = s.empty() ? ' ' : s[0];
  }

  // Build char -> position mapping
  std::unordered_map<char, int> char_to_pos;
  for (int i = 0; i < n; i++) {
    char_to_pos[layout_keys[i]] = i;
    if (layout_keys[i] >= 'a' && layout_keys[i] <= 'z') {
      char_to_pos[layout_keys[i] - 32] = i;
    }
  }

  // Calculate fingers based on x position (layout-independent)
  double min_x = *std::min_element(px.begin(), px.end());
  double max_x = *std::max_element(px.begin(), px.end());

  std::vector<int> fingers(n), hands(n);
  for (int i = 0; i < n; i++) {
    fingers[i] = get_finger_for_x_position(px[i], min_x, max_x);
    hands[i] = get_hand_for_finger(fingers[i]);
  }

  double base_effort = 0.0;
  double same_finger_effort = 0.0;
  double same_hand_effort = 0.0;
  double row_change_effort = 0.0;
  double trigram_effort = 0.0;
  int same_finger_count = 0;
  int same_hand_count = 0;
  int hand_alternation_count = 0;
  int trigram_count = 0;

  // Get text length for proper scaling (must match calculate_effort)
  double text_len = static_cast<double>(combined_text.length());

  // Base effort
  for (size_t i = 0; i < cl.size(); i++) {
    char c = cl[i];
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end() && c >= 'A' && c <= 'Z') {
      it = char_to_pos.find(c + 32);
    }
    if (it != char_to_pos.end()) {
      int pos = it->second;
      // CRITICAL: Must scale by text_len to match calculate_effort()
      // Use x-position-based effort (layout-independent!)
      base_effort += base_key_effort_x(pr[pos], px[pos], fingers[pos], min_x, max_x) * cf[i] * text_len;
    }
  }

  // Bigram and trigram analysis
  int prev_prev_pos = -1;
  int prev_pos = -1;
  for (size_t i = 0; i < combined_text.length(); i++) {
    char c = std::tolower(combined_text[i]);
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end()) continue;

    int curr_pos = it->second;

    // Bigram analysis
    if (prev_pos >= 0) {
      if (fingers[prev_pos] == fingers[curr_pos] && prev_pos != curr_pos) {
        same_finger_count++;
        same_finger_effort += same_finger_penalty(
          pr[prev_pos], pr[curr_pos], pc[prev_pos], pc[curr_pos]
        );
      } else if (hands[prev_pos] == hands[curr_pos]) {
        same_hand_count++;
        same_hand_effort += same_hand_penalty(
          pr[prev_pos], pr[curr_pos], pc[prev_pos], pc[curr_pos],
          fingers[prev_pos], fingers[curr_pos]
        );
        row_change_effort += row_change_penalty(pr[prev_pos], pr[curr_pos]);
      } else {
        hand_alternation_count++;
      }
    }

    // Trigram analysis
    if (prev_prev_pos >= 0 && prev_pos >= 0) {
      int hand0 = hands[prev_prev_pos];
      int hand1 = hands[prev_pos];
      int hand2 = hands[curr_pos];

      if (hand0 == hand1 && hand1 == hand2) {
        trigram_count++;
        bool is_left = (hand0 == 0);
        trigram_effort += same_hand_trigram_penalty(
          fingers[prev_prev_pos], fingers[prev_pos], fingers[curr_pos], is_left
        );
      }
    }

    prev_prev_pos = prev_pos;
    prev_pos = curr_pos;
  }

  return List::create(
    Named("base_effort") = base_effort,
    Named("same_finger_effort") = same_finger_effort,
    Named("same_hand_effort") = same_hand_effort,
    Named("row_change_effort") = row_change_effort,
    Named("trigram_effort") = trigram_effort,
    Named("total_effort") = base_effort + 3.0 * same_finger_effort +
                            same_hand_effort + 0.5 * row_change_effort +
                            0.3 * trigram_effort,
    Named("same_finger_bigrams") = same_finger_count,
    Named("same_hand_bigrams") = same_hand_count,
    Named("hand_alternations") = hand_alternation_count,
    Named("same_hand_trigrams") = trigram_count
  );
}

// Generate random layout
// [[Rcpp::export]]
CharacterVector random_layout(CharacterVector keys) {
  int n = keys.size();
  std::vector<int> indices(n);
  std::iota(indices.begin(), indices.end(), 0);
  
  // Use local RNG for shuffling
  static thread_local std::mt19937 rng(std::random_device{}());
  std::shuffle(indices.begin(), indices.end(), rng);

  CharacterVector result(n);
  for (int i = 0; i < n; i++) {
    result[i] = keys[indices[i]];
  }
  return result;
}
