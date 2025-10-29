
# Project 03 – ALB, ASG, RDS, and Redis Architecture on AWS

**Objective:** Build a complete, production-grade cloud architecture on **AWS** using **OpenTofu**, integrating compute, networking, database, caching, and monitoring layers.

---

## Overview

This project provisions a **multi-tier web application environment** with full automation through **Infrastructure-as-Code (IaC)**, featuring:

* **VPC & Subnets:** Modular private and public network design from the reusable VPC module
* **Application Load Balancer (ALB):** Public entry point distributing traffic across EC2 instances
* **Auto Scaling Group (ASG):** Dynamically manages EC2 capacity based on CPU utilization
* **Launch Template:** Defines reusable configuration for EC2 instances (AMI, type, user data, IAM profile)
* **RDS (PostgreSQL):** Managed relational database hosted in private subnets
* **Redis (ElastiCache):** In-memory caching layer for application performance
* **CloudWatch Integration:** Metrics and scaling policies for automated elasticity
* **Security Groups:** Layered access control between internet, web, app, and data tiers

---

## Highlights

* Hands-on implementation of a **3-tier architecture** — Web, App, and Data
* Demonstrates **scalability, isolation, and fault-tolerance** using AWS native services
* Fully automated with **OpenTofu**, leveraging reusable modules and variable-driven configuration
* Incorporates **monitoring and autoscaling** for real-world infrastructure behavior
* Emphasizes **secure network boundaries** and least-privilege IAM design

> This lab simulates a production-like AWS environment, combining modular design, automation, and observability — a foundational pattern for deploying real-world cloud applications with OpenTofu.
