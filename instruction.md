# Assignment 2 – Architecture Design and Deployment

## Scenario

A university with 8,000 students and about 400 staff is moving all exams and assignment submissions online. You are the cloud architect for this platform.

- **Users:** students sit timed exams and upload assignments; tutors create exams, mark and release results; administrators manage users and schedules.
- **Features:** role-based sign-in, timed MCQ and short-answer exams, answers autosaved every 30 seconds, auto-marking of MCQs, file uploads (PDF or ZIP, up to 50 MB), and email when results are released.
- **Load:** 300–500 concurrent users normally; at exam-week peak, 3,000 students start one exam within 5 minutes.
- **Targets:** 99.9% availability during exams, survives the loss of one Availability Zone, at most 5 minutes of answers lost (RPO), restored within 1 hour (RTO), records kept for 5 years encryption in transit and at rest.

## Tasks

### Task 1 – Architecture design

Draw the full production architecture: VPC with public and private subnets across two Availability Zones, edge layer (DNS, CDN, WAF), frontend, API and compute, authentication, database, file storage with lifecycle rules, asynchronous processing for marking and emails, monitoring, secrets and a CI/CD pipeline. Add two short request walkthroughs:

1. A student opens an exam and answers autosave.
2. A student uploads a 40 MB assignment and the tutor is notified.

Explain in at most 300 words how the design handles the exam peak and the loss of one AZ.

### Task 2 – Service documentation

Document every service in a table like this:

| Service | Role | Why over an alternative | Connects to |
|---|---|---|---|
| Amazon S3 | Stores assignment files | Cheaper and more durable than EBS; presigned URLs keep 50 MB uploads off the API | CloudFront, Lambda, IAM |

### Task 3 – Implementation

- Build the full architecture in the Cloud Architecture Lab and simulate both walkthroughs and one AZ failure.

## Deliverables

Submit in your own repository:

- `README.md` – summary, deploy and tear-down steps
- `architecture/` – diagram and walkthroughs
- `docs/services.md` – service table
- `evidence/` – Cloud Architecture Lab Image

## Marking rubric

| Criterion | Marks | Full marks | Partial | Low |
|---|---|---|---|---|
| AWS architecture design | 2 | All components in correct tiers across two AZs; walkthroughs accurate; peak and AZ loss handled | Minor gaps or weak peak/AZ reasoning (1–1.5) | Single AZ, public database or major parts missing (0–0.5) |
| AWS service documentation | 2 | Every service justified against an alternative, with configuration | Generic reasons or thin configuration (1–1.5) | List only (0–0.5) |
| Implementation – Cloud Architecture Lab | 2 | Full build; both flows and AZ failure simulated with evidence | Partial build or evidence (1) | None (0) |
| Implementation – AWS deployment | 2 | Frontend, API, two-AZ database, S3 uploads and async step working in the video | Some parts working (1) | Not working (0) |
| Implementation – IaC and CI/CD | 2 | Fully reproducible from code; push to main redeploys automatically | Partly in code or manual pipeline steps (1) | Console-built, no pipeline (0) |
| **Total** | **10** | | | |

The tutor may ask you to explain your work in a short viva.