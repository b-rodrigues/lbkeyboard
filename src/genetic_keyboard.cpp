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
int get_finger_for_column(int col) {
  // Left hand columns 0-5, Right hand columns 6-13
  // Columns: 0-1 = pinky, 2 = ring, 3 = middle, 4-5 = index (left hand)
  //          6-7 = index, 8 = middle, 9 = ring, 10+ = pinky (right hand)
  if (col <= 1) return 0;       // left pinky
  if (col == 2) return 1;       // left ring
  if (col == 3) return 2;       // left middle
  if (col <= 5) return 3;       // left index
  if (col <= 7) return 6;       // right index
  if (col == 8) return 7;       // right middle
  if (col == 9) return 8;       // right ring
  return 9;                      // right pinky
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
double row_penalty(int row) {
  switch(row) {
    case 0: return 3.0;   // Number row - far reach
    case 1: return 1.5;   // Top row - moderate reach
    case 2: return 1.0;   // Home row - no reach needed
    case 3: return 1.5;   // Bottom row - moderate reach
    default: return 2.0;
  }
}

// Finger strength/dexterity penalty (weaker fingers = higher penalty)
double finger_penalty(int finger) {
  // Pinkies are weakest, index fingers strongest
  // finger 0,9 = pinkies, 1,8 = ring, 2,7 = middle, 3,6 = index, 4,5 = thumbs
  switch(finger % 5) {
    case 0: return 2.0;   // Pinky - weakest
    case 1: return 1.3;   // Ring finger
    case 2: return 1.0;   // Middle finger - strongest for typing
    case 3: return 1.1;   // Index finger
    case 4: return 1.5;   // Thumb (rarely used for letters)
    default: return 1.5;
  }
}

// Distance from home position penalty
// Lateral movement (horizontal) is penalized
double home_distance_penalty(int col, int finger) {
  // Home positions for each finger (approximate column)
  int home_col;
  switch(finger) {
    case 0: home_col = 0; break;   // left pinky
    case 1: home_col = 2; break;   // left ring
    case 2: home_col = 3; break;   // left middle
    case 3: home_col = 4; break;   // left index
    case 6: home_col = 7; break;   // right index
    case 7: home_col = 8; break;   // right middle
    case 8: home_col = 9; break;   // right ring
    case 9: home_col = 10; break;  // right pinky
    default: home_col = col;
  }

  double dist = std::abs(col - home_col);
  return 1.0 + 0.3 * dist;  // 30% penalty per column away from home
}

// Base effort for a single key
double base_key_effort(int row, int col, int finger) {
  return row_penalty(row) * finger_penalty(finger) * home_distance_penalty(col, finger);
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
// [[Rcpp::export]]
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
    double w_row_change = 0.5
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

  // Calculate finger assignments
  std::vector<int> fingers(n);
  std::vector<int> hands(n);
  for (int i = 0; i < n; i++) {
    fingers[i] = get_finger_for_column(pos_col[i]);
    hands[i] = get_hand_for_finger(fingers[i]);
  }

  double total_effort = 0.0;

  // Base effort (weighted by character frequency)
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
      double base = base_key_effort(pos_row[pos], pos_col[pos], fingers[pos]);
      total_effort += w_base * base * char_freq[i];
    }
  }

  // Bigram effort (process text for consecutive pairs)
  int prev_pos = -1;
  for (size_t i = 0; i < text.length(); i++) {
    char c = std::tolower(text[i]);
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end()) continue;

    int curr_pos = it->second;

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

    prev_pos = curr_pos;
  }

  return total_effort;
}

// -----------------------------------------------------------------
// GENETIC ALGORITHM OPERATORS
// -----------------------------------------------------------------

// Thread-local random number generator
std::mt19937& get_rng() {
  static thread_local std::mt19937 rng(std::random_device{}());
  return rng;
}

// Partially Mapped Crossover (PMX) for permutation chromosomes
std::vector<char> pmx_crossover(
    const std::vector<char>& parent1,
    const std::vector<char>& parent2
) {
  int n = parent1.size();
  std::vector<char> child(n, '\0');

  std::uniform_int_distribution<int> dist(0, n - 1);
  int start = dist(get_rng());
  int end = dist(get_rng());
  if (start > end) std::swap(start, end);

  // Copy segment from parent1
  std::unordered_map<char, char> mapping;
  for (int i = start; i <= end; i++) {
    child[i] = parent1[i];
    mapping[parent1[i]] = parent2[i];
  }

  // Fill rest from parent2, resolving conflicts
  for (int i = 0; i < n; i++) {
    if (i >= start && i <= end) continue;

    char c = parent2[i];
    while (mapping.count(c) > 0) {
      c = mapping[c];
    }
    child[i] = c;
  }

  return child;
}

// Order Crossover (OX) - alternative crossover operator
std::vector<char> ox_crossover(
    const std::vector<char>& parent1,
    const std::vector<char>& parent2
) {
  int n = parent1.size();
  std::vector<char> child(n, '\0');
  std::vector<bool> used(256, false);

  std::uniform_int_distribution<int> dist(0, n - 1);
  int start = dist(get_rng());
  int end = dist(get_rng());
  if (start > end) std::swap(start, end);

  // Copy segment from parent1
  for (int i = start; i <= end; i++) {
    child[i] = parent1[i];
    used[(unsigned char)parent1[i]] = true;
  }

  // Fill rest with order from parent2
  int j = (end + 1) % n;
  for (int i = 0; i < n; i++) {
    int idx = (end + 1 + i) % n;
    char c = parent2[idx];
    if (!used[(unsigned char)c]) {
      while (child[j] != '\0') {
        j = (j + 1) % n;
      }
      child[j] = c;
      used[(unsigned char)c] = true;
      j = (j + 1) % n;
    }
  }

  return child;
}

// Swap mutation
void swap_mutation(std::vector<char>& layout, double mutation_rate) {
  std::uniform_real_distribution<double> prob(0.0, 1.0);
  std::uniform_int_distribution<int> pos(0, layout.size() - 1);

  if (prob(get_rng()) < mutation_rate) {
    int i = pos(get_rng());
    int j = pos(get_rng());
    std::swap(layout[i], layout[j]);
  }
}

// Scramble mutation (scramble a random segment)
void scramble_mutation(std::vector<char>& layout, double mutation_rate) {
  std::uniform_real_distribution<double> prob(0.0, 1.0);

  if (prob(get_rng()) < mutation_rate) {
    int n = layout.size();
    std::uniform_int_distribution<int> dist(0, n - 1);
    int start = dist(get_rng());
    int len = std::min(3, n - start);  // Scramble up to 3 keys
    std::shuffle(layout.begin() + start, layout.begin() + start + len, get_rng());
  }
}

// Inversion mutation
void inversion_mutation(std::vector<char>& layout, double mutation_rate) {
  std::uniform_real_distribution<double> prob(0.0, 1.0);

  if (prob(get_rng()) < mutation_rate) {
    int n = layout.size();
    std::uniform_int_distribution<int> dist(0, n - 1);
    int start = dist(get_rng());
    int end = dist(get_rng());
    if (start > end) std::swap(start, end);
    std::reverse(layout.begin() + start, layout.begin() + end + 1);
  }
}

// Tournament selection
int tournament_select(const std::vector<double>& fitness, int tournament_size) {
  std::uniform_int_distribution<int> dist(0, fitness.size() - 1);

  int best = dist(get_rng());
  double best_fit = fitness[best];

  for (int i = 1; i < tournament_size; i++) {
    int candidate = dist(get_rng());
    if (fitness[candidate] < best_fit) {  // Lower effort = better
      best = candidate;
      best_fit = fitness[candidate];
    }
  }

  return best;
}

// -----------------------------------------------------------------
// MAIN GENETIC ALGORITHM
// -----------------------------------------------------------------

// [[Rcpp::export]]
List optimize_keyboard_layout(
    std::vector<char> initial_layout,
    std::vector<double> pos_x,
    std::vector<double> pos_y,
    std::vector<int> pos_row,
    std::vector<int> pos_col,
    std::vector<std::string> text_samples,
    std::vector<double> char_freq,
    std::vector<char> char_list,
    int population_size = 100,
    int generations = 500,
    double mutation_rate = 0.1,
    double crossover_rate = 0.8,
    int tournament_size = 5,
    int elite_count = 2,
    double w_base = 1.0,
    double w_same_finger = 3.0,
    double w_same_hand = 1.0,
    double w_row_change = 0.5,
    bool verbose = true
) {
  int n_keys = initial_layout.size();

  // Combine all text samples
  std::string combined_text;
  for (const auto& text : text_samples) {
    combined_text += text + " ";
  }

  // Initialize population
  std::vector<std::vector<char>> population(population_size);
  std::vector<double> fitness(population_size);

  // First individual is the initial layout
  population[0] = initial_layout;

  // Rest are random permutations
  for (int i = 1; i < population_size; i++) {
    population[i] = initial_layout;
    std::shuffle(population[i].begin(), population[i].end(), get_rng());
  }

  // Calculate initial fitness
  for (int i = 0; i < population_size; i++) {
    fitness[i] = calculate_effort(
      population[i], pos_x, pos_y, pos_row, pos_col,
      combined_text, char_freq, char_list,
      w_base, w_same_finger, w_same_hand, w_row_change
    );
  }

  // Track best solution
  int best_idx = std::min_element(fitness.begin(), fitness.end()) - fitness.begin();
  std::vector<char> best_layout = population[best_idx];
  double best_fitness = fitness[best_idx];

  // History for convergence tracking
  std::vector<double> history_best(generations);
  std::vector<double> history_mean(generations);

  // Evolution loop
  for (int gen = 0; gen < generations; gen++) {
    std::vector<std::vector<char>> new_population(population_size);
    std::vector<double> new_fitness(population_size);

    // Elitism: copy best individuals
    std::vector<int> sorted_indices(population_size);
    std::iota(sorted_indices.begin(), sorted_indices.end(), 0);
    std::partial_sort(sorted_indices.begin(), sorted_indices.begin() + elite_count,
                      sorted_indices.end(),
                      [&fitness](int a, int b) { return fitness[a] < fitness[b]; });

    for (int i = 0; i < elite_count; i++) {
      new_population[i] = population[sorted_indices[i]];
      new_fitness[i] = fitness[sorted_indices[i]];
    }

    // Generate rest of population
    std::uniform_real_distribution<double> prob(0.0, 1.0);

    for (int i = elite_count; i < population_size; i++) {
      // Selection
      int parent1_idx = tournament_select(fitness, tournament_size);
      int parent2_idx = tournament_select(fitness, tournament_size);

      std::vector<char> child;

      // Crossover
      if (prob(get_rng()) < crossover_rate) {
        child = ox_crossover(population[parent1_idx], population[parent2_idx]);
      } else {
        child = population[parent1_idx];
      }

      // Mutation (apply multiple mutation types with lower individual rates)
      swap_mutation(child, mutation_rate);
      scramble_mutation(child, mutation_rate * 0.3);
      inversion_mutation(child, mutation_rate * 0.2);

      new_population[i] = child;
      new_fitness[i] = calculate_effort(
        child, pos_x, pos_y, pos_row, pos_col,
        combined_text, char_freq, char_list,
        w_base, w_same_finger, w_same_hand, w_row_change
      );
    }

    population = std::move(new_population);
    fitness = std::move(new_fitness);

    // Update best
    int gen_best = std::min_element(fitness.begin(), fitness.end()) - fitness.begin();
    if (fitness[gen_best] < best_fitness) {
      best_layout = population[gen_best];
      best_fitness = fitness[gen_best];
    }

    // Track history
    history_best[gen] = best_fitness;
    double mean_fit = 0.0;
    for (double f : fitness) mean_fit += f;
    history_mean[gen] = mean_fit / population_size;

    if (verbose && (gen + 1) % 50 == 0) {
      Rcpp::Rcout << "Generation " << (gen + 1) << ": best effort = "
                  << best_fitness << ", mean = " << history_mean[gen] << std::endl;
    }

    // Check for user interrupt
    if (gen % 10 == 0) {
      Rcpp::checkUserInterrupt();
    }
  }

  // Convert best layout to R-compatible format
  CharacterVector best_layout_r(n_keys);
  for (int i = 0; i < n_keys; i++) {
    best_layout_r[i] = std::string(1, best_layout[i]);
  }

  return List::create(
    Named("layout") = best_layout_r,
    Named("effort") = best_fitness,
    Named("history_best") = history_best,
    Named("history_mean") = history_mean,
    Named("generations") = generations,
    Named("population_size") = population_size
  );
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
    double w_row_change = 0.5
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
    w_base, w_same_finger, w_same_hand, w_row_change
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

  // Calculate fingers
  std::vector<int> fingers(n), hands(n);
  for (int i = 0; i < n; i++) {
    fingers[i] = get_finger_for_column(pc[i]);
    hands[i] = get_hand_for_finger(fingers[i]);
  }

  double base_effort = 0.0;
  double same_finger_effort = 0.0;
  double same_hand_effort = 0.0;
  double row_change_effort = 0.0;
  int same_finger_count = 0;
  int same_hand_count = 0;
  int hand_alternation_count = 0;

  // Base effort
  for (size_t i = 0; i < cl.size(); i++) {
    char c = cl[i];
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end() && c >= 'A' && c <= 'Z') {
      it = char_to_pos.find(c + 32);
    }
    if (it != char_to_pos.end()) {
      int pos = it->second;
      base_effort += base_key_effort(pr[pos], pc[pos], fingers[pos]) * cf[i];
    }
  }

  // Bigram analysis
  int prev_pos = -1;
  for (size_t i = 0; i < combined_text.length(); i++) {
    char c = std::tolower(combined_text[i]);
    auto it = char_to_pos.find(c);
    if (it == char_to_pos.end()) continue;

    int curr_pos = it->second;

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
    prev_pos = curr_pos;
  }

  return List::create(
    Named("base_effort") = base_effort,
    Named("same_finger_effort") = same_finger_effort,
    Named("same_hand_effort") = same_hand_effort,
    Named("row_change_effort") = row_change_effort,
    Named("total_effort") = base_effort + 3.0 * same_finger_effort +
                            same_hand_effort + 0.5 * row_change_effort,
    Named("same_finger_bigrams") = same_finger_count,
    Named("same_hand_bigrams") = same_hand_count,
    Named("hand_alternations") = hand_alternation_count
  );
}

// Generate random layout
// [[Rcpp::export]]
CharacterVector random_layout(CharacterVector keys) {
  int n = keys.size();
  std::vector<int> indices(n);
  std::iota(indices.begin(), indices.end(), 0);
  std::shuffle(indices.begin(), indices.end(), get_rng());

  CharacterVector result(n);
  for (int i = 0; i < n; i++) {
    result[i] = keys[indices[i]];
  }
  return result;
}
