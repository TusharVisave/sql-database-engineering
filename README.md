# DSA in Java

A structured collection of **Data Structures and Algorithms problems implemented in Java**, focused on building strong problem-solving skills, understanding common DSA patterns, and writing clean, testable code.

The repository follows a progressive approach from fundamental array problems to string-based patterns and will continue toward more advanced data structures and algorithms.

---

## 🎯 Objectives

* Build strong DSA fundamentals.
* Learn common problem-solving patterns.
* Implement algorithms from scratch in Java.
* Understand time and space complexity.
* Practice edge-case handling.
* Write clean and maintainable code.
* Validate solutions using automated JUnit tests.
* Maintain a structured GitHub problem-solving portfolio.

---

# 📚 Problems

|  # | Problem                         | Difficulty | Pattern            | Solution                                                                         |
| -: | ------------------------------- | ---------- | ------------------ | -------------------------------------------------------------------------------- |
|  1 | Two Sum                         | Easy       | Hash Map           | [View Solution](src/main/java/com/Tushar/dsajava/arrays/twosum)                  |
|  2 | Best Time to Buy and Sell Stock | Easy       | One Pass           | [View Solution](src/main/java/com/Tushar/dsajava/arrays/besttimebuyandsellstock) |
|  3 | Maximum Subarray                | Medium     | Kadane's Algorithm | [View Solution](src/main/java/com/Tushar/dsajava/arrays/maximumsubarray)         |
|  4 | Valid Anagram                   | Easy       | Frequency Map      | [View Solution](src/main/java/com/Tushar/dsajava/strings/validanagram)           |
|  5 | Valid Palindrome                | Easy       | Two Pointers       | [View Solution](src/main/java/com/Tushar/dsajava/strings/validpalindrome)        |

---

# 🧠 Patterns Covered

## Arrays

### Hash Map

Used to efficiently store and look up previously seen values.

**Problem:**

* Two Sum

### One Pass

Processes the array in a single traversal while maintaining the required state.

**Problem:**

* Best Time to Buy and Sell Stock

### Kadane's Algorithm

Used to find the maximum sum of a contiguous subarray efficiently.

**Problem:**

* Maximum Subarray

---

## Strings

### Frequency Map

Counts character frequencies to compare the composition of two strings.

**Problem:**

* Valid Anagram

### Two Pointers

Uses pointers from both ends of a string and moves them toward the center.

**Problem:**

* Valid Palindrome

---

# 📁 Project Structure

```text
dsa-java/
│
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/
│   │           └── Tushar/
│   │               └── dsajava/
│   │                   │
│   │                   ├── arrays/
│   │                   │   ├── twosum/
│   │                   │   │   ├── Solution.java
│   │                   │   │   └── README.md
│   │                   │   │
│   │                   │   ├── besttimebuyandsellstock/
│   │                   │   │   ├── Solution.java
│   │                   │   │   └── README.md
│   │                   │   │
│   │                   │   └── maximumsubarray/
│   │                   │       ├── Solution.java
│   │                   │       └── README.md
│   │                   │
│   │                   └── strings/
│   │                       ├── validanagram/
│   │                       │   ├── Solution.java
│   │                       │   └── README.md
│   │                       │
│   │                       └── validpalindrome/
│   │                           ├── Solution.java
│   │                           └── README.md
│   │
│   └── test/
│       └── java/
│           └── com/
│               └── Tushar/
│                   └── dsajava/
│                       ├── arrays/
│                       └── strings/
│
├── README.md
├── pom.xml
└── .gitignore
```

---

# 🏗️ Package Structure

All problems use a single consistent package root:

```text
com.Tushar.dsajava
```

The repository is organized by DSA category:

```text
com.Tushar.dsajava
├── arrays
└── strings
```

This avoids maintaining multiple package roots and keeps the Java project consistent as more problems are added.

---

# 📝 Problem Documentation Structure

Each problem contains its own `README.md` with:

1. Problem
2. Approach
3. Why This Approach?
4. Time Complexity
5. Space Complexity
6. Edge Cases

This makes every solution independently understandable and interview-ready.

---

# 🧪 Testing

Solutions are tested using **JUnit 5**.

Tests cover:

* Normal cases
* Edge cases
* Empty input
* Single-element/single-character input
* Invalid input scenarios where applicable

Run all tests using:

```bash
mvn test
```

Expected result:

```text
Tests run: ...
Failures: 0
Errors: 0
Skipped: 0

BUILD SUCCESS
```

---

# 🔍 Current Problems

## 1. Two Sum

**Pattern:** Hash Map

Finds two numbers in an array whose sum equals a given target.

**Key idea:**

Store previously seen values in a hash map and check whether the required complement already exists.

**Complexity:**

```text
Time  → O(n)
Space → O(n)
```

---

## 2. Best Time to Buy and Sell Stock

**Pattern:** One Pass

Finds the maximum profit from buying and selling a stock once.

**Key idea:**

Maintain the minimum price seen so far and calculate the maximum possible profit at every position.

**Complexity:**

```text
Time  → O(n)
Space → O(1)
```

---

## 3. Maximum Subarray

**Pattern:** Kadane's Algorithm

Finds the contiguous subarray with the largest sum.

**Key idea:**

At every element, decide whether to extend the current subarray or start a new one.

**Complexity:**

```text
Time  → O(n)
Space → O(1)
```

---

## 4. Valid Anagram

**Pattern:** Frequency Map

Determines whether two strings contain the same characters with the same frequencies.

**Key idea:**

Count the frequency of every character in the first string and decrement those frequencies while processing the second string.

A length check is performed first to immediately reject strings of different lengths.

**Complexity:**

```text
Time  → O(n)
Space → O(k)
```

where `k` represents the number of distinct characters.

### Important Edge Cases

* Different-length strings
* Empty strings
* Single characters
* Different character frequencies

---

## 5. Valid Palindrome

**Pattern:** Two Pointers

Determines whether a string is a palindrome after ignoring non-alphanumeric characters and letter case.

**Key idea:**

Use two pointers:

```text
left  → beginning
right → end
```

Skip non-alphanumeric characters from both sides and compare the remaining characters.

**Complexity:**

```text
Time  → O(n)
Space → O(1)
```

### Important Edge Cases

* Empty string
* Single character
* Mixed case
* Spaces
* Punctuation
* String containing only punctuation

Example:

```text
A man, a plan, a canal: Panama
```

returns:

```text
true
```

while:

```text
race a car
```

returns:

```text
false
```

---

# 📊 Complexity Summary

| Problem                         | Time | Space | Pattern            |
| ------------------------------- | ---: | ----: | ------------------ |
| Two Sum                         | O(n) |  O(n) | Hash Map           |
| Best Time to Buy and Sell Stock | O(n) |  O(1) | One Pass           |
| Maximum Subarray                | O(n) |  O(1) | Kadane's Algorithm |
| Valid Anagram                   | O(n) |  O(k) | Frequency Map      |
| Valid Palindrome                | O(n) |  O(1) | Two Pointers       |

---

# 🛠️ Technologies

* **Java 21**
* **Maven**
* **JUnit 5**
* **IntelliJ IDEA**
* **Git**
* **GitHub**

---

# 🌱 Learning Roadmap

The repository will progressively cover the major DSA patterns and data structures.

```text
Arrays
  ↓
Strings
  ↓
Hashing
  ↓
Linked Lists
  ↓
Stacks & Queues
  ↓
Binary Search
  ↓
Trees
  ↓
Binary Search Trees
  ↓
Heaps / Priority Queues
  ↓
Graphs
  ↓
Recursion & Backtracking
  ↓
Dynamic Programming
  ↓
Advanced Algorithms
```

---

# 📈 Progress

### Arrays

* [x] Two Sum
* [x] Best Time to Buy and Sell Stock
* [x] Maximum Subarray

### Strings

* [x] Valid Anagram
* [x] Valid Palindrome

### Upcoming

* [ ] More Hashing Problems
* [ ] Linked Lists
* [ ] Stacks
* [ ] Queues
* [ ] Binary Search
* [ ] Trees
* [ ] Heaps
* [ ] Graphs
* [ ] Recursion
* [ ] Backtracking
* [ ] Dynamic Programming

---

# 🎯 Goal

The goal of this repository is to develop strong **problem-solving ability and DSA fundamentals in Java** through consistent implementation and testing.

The focus is on:

```text
Understand the Problem
        ↓
Identify the Pattern
        ↓
Design the Approach
        ↓
Implement in Java
        ↓
Analyze Complexity
        ↓
Test Edge Cases
        ↓
Document the Solution
```

Each problem is intended to strengthen both **coding ability and algorithmic reasoning** for technical interviews and competitive programming.
