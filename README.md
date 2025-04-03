# **Opinion Dynamics and Echo Chambers in Social Media: An Agent-Based Simulation Approach**

This repository presents a simulation study on **opinion formation and polarization in online social networks**, using an **agent-based model** to explore how different algorithmic recommendation strategies affect the emergence of **echo chambers**.

> 📘 **Course Project**  
> This project is the final assignment for the course *Computational Social Science* (Spring 2024), jointly offered to students in the **Department of Political Science** and the **Department of Sociology**, **National Taiwan University**.

## 🧠 Overview

With the rise of social media, recommendation algorithms play a growing role in shaping our exposure to information—and by extension, our **ideologies and social interactions**. This project simulates how users' opinions evolve over time under various content-pushing strategies, such as:
- **Preference-based (self-reinforcing)** recommendation  
- **Network-based** recommendation  
- **Neutral/fair** (random) recommendation  

We model users as **agents** embedded in a social network, updating their ideological inclinations based on what they are exposed to, and disconnecting from others with opposing views when differences grow too large.

## 🧪 Model Description

- **Agents** hold probabilistic preferences over competing ideologies.
- Each round (tick), agents receive information based on a chosen **recommendation strategy**, and update their preferences accordingly.
- Agents disconnect from those with opposing views when ideological distance becomes too great.
- **Key variables**: learning rate (α), recommendation method, and network structure.

## 📊 Simulation Modes

Three recommendation strategies are compared:
1. **Preference-based ("Echo Chamber")**: Content is pushed based on current ideological preferences.
2. **Network-based**: Recommendations reflect the ideologies of social ties.
3. **Fair recommendation**: Equal probability of exposure to all ideologies.

We also test how different **network structures** (e.g. fully connected vs. modular networks) influence the speed and pattern of polarization.

## 🔍 Key Findings

- **Self-reinforcing algorithms** rapidly push agents toward extreme positions, leading to ideological isolation and fragmented networks.
- **Network-based recommendations** preserve neutrality longer, but only if **learning rate** is low (i.e. people aren't too easily swayed).
- **Fair recommendation** avoids early polarization, but still leads to network fragmentation under high learning rates.

## 💻 Environment

- **Language**: NetLogo
- **Version**: 6.4.0


## 📜 License

MIT License. See `LICENSE` for details.
