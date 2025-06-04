# Insurance Analytics Executive Report

 Table of Contents:
 
- [Project Background](#project-background)
- [Executive Overview](#executive-overview)
- [Insights Deep-Dive](#insights-deep-dive)
  - [Premiums](#premiums)
  - [Claims](#claims)
  - [Digital Sales Adoption Rate](#digital-sales-adoption-rate)
- [Summary Recommendations](#summary-recommendations)
---
## Project Background

This project simulates the complete analytics pipeline for an insurance business, covering the period from **2020 to 2024**. It demonstrates how I've leveraged my industry know-how to drive executive decision-making, from data generation with Python and business KPI design thorugh SQL modeling, to final delivery of executive-level insights in Power BI.

The initiative is designed to showcase:
- **Business-driven data modeling:** Using star schema to optimize reporting.
- **Actionable metrics:** Monthly premiums, claims, expenses and digital adoption.
- **Executive reporting:** Insights that inform profitability and operational efficiency.
- **Story behind data:** Answering How and Why it happens across data fluctuation

![ERD - Insurance Analystics](https://github.com/user-attachments/assets/4d9eb030-1545-402d-8504-66d3c7a677fb)
Enterprise Relationship Diagram - Insurance Analytics

## Executive Overview

The insurance dataset analysis of 145k records (100k policies + 45k claims) across operational years of 2020-2024, reveals robust underwritting results with an average annual Net Underwritting Income of approximately €103 million. 
The performance is largely attributed to the strong operational discipline in the Auto and Transportation line of business, which posted combined ratios of 52.6% and 68.1% respectively - below industry benchmarks, indicating effective risk subscription criteria. In contrast, gains were partially offset by Engineering line of business facing significant challenges, with a combined ratio of 125.6% over the same period, highlightning the need for enhanced underwritting strategies or targeted loss prevention for the lob. 
Location analysis further reveals that Portugal and Sweden outperformed other regions, benefiting from excepetional results in Transportation and Auto, as well as notably lower large claim amounts in Engineering and Liability. These favorable outcomes suggest strong market positioning, superior underwriitting, and effective loss prevention strategies in these countries. 

![Executive Overview](https://github.com/user-attachments/assets/93419ea1-6cd6-4774-a1b1-bddf8cb5500a)

## Insights Deep-Dive

### Premiums

- Averaged €2.2 billion per year, totaling €11 billion across the five-year period.
- Reflects issuance of 100,000 policies from 2020 to 2024.
- Auto and Residence lines recorded the highest number of policies issued, underscoring their central role in the portfolio's customer reach and risk diversification. 
- Premium volumes were primarily influenced by high-value policies in the Engineering and Liability lines, which together accounted for 58% of total written premium.
- First quarter consistent saw a surge in policy issuance - marking a seasonal peak
- Third quarter reflected a downturn, with fewer policies underwritten during this period

Executives should consider levaraging the Auto and Residence books for cross-selling and customer retention strategies. Also addressing seasonality with marketing pushes or product launches in the third quarter to stabilize new business flows year-round.
  
![Written Premium Table](https://github.com/user-attachments/assets/5f02204b-f996-4559-8871-b9ecf970b842)

### Claims

- The porfolio averaged a frenquecy of 9,000 claims per year.
- Average claim severity was approximately €220,000 across the analyzed period.
- 33% of all claims were processed and paid, with an average processing time of 56 days - an indicator of operational efficiency however indicates the need to strength claims operational process in order to close more claims.
- The highest claims amounts were concentrated in the Engineering and Liability lines, due to several large losses - mostly in Italy and Netherlands. These segments drove loss ratios and combined ratios above 100% for Engineering, and around 95% for Liability.
- Expenses represented 4.6% of Earned Premium overall. Transportation line incurred the highest share of expenses, meriting attention for cost control initiatives.

Executives should consider enhance underwriting criteria and risk selection in Engineering and Liability to curb large-loss volatility and restore profitability in these segments - perhaps through targeted risk engineering or client partnership programs. Furthermore optimize expenses processes within the Transportation line, ensuring efficiency gains. Last but not least, to continue investing in claims automation and analytics to further elevate customer experience. 

![Insight Deep Dive - Claims](https://github.com/user-attachments/assets/085bce0e-efd4-4301-91fa-f573eeb7b3f6)

### Digital Sales Adoption Rate

- The digital adoption rate dropped from 50% in 2020 to 35.5% by the end of 2022, reflecting a period of stagnation and potential customer or process friction
- Folowwing a strategic realignment in marketing and improvements to the digital sales application, digital adoption rebounded sharply, reaching 70.1% by 2024

The trend signaled an underlying process challenges that has lowered digital conversions. Seems that leadership responded well with two approaches retooling the market strategy to better engage digital-first clients and investing in a more intuitive digital sales platform. The interventions yielded immediate results, transforming the sales landscape and positioning digital as the primary growth channel for new business. 

![Sales Digital Adoption Rate](https://github.com/user-attachments/assets/ff91df50-38bf-4a7a-95a0-7899bf06723c)

---
## Summary Recommendations

### Premiums
- Levaraging the Auto and Residence books for cross-selling and customer retention strategies.
- Balancing the portfolio by developing mid-sized offerings in Engineering and Liability to reduce reliance on very large contracts.
- Addresing seasonality with marketing pushes or product launches in the third quarter to stabilize new business flows year-round.

### Claims
- Enhance underwritting criteria and risk selection in Engineering and Liability to curb large-loss volatility and restore profitability in these segments.
- Strengthen claims prevention and loss mitigation initiatives for high-ticket business, possibly through targeted risk engineering or client partnership programs.
- Benchmark and optimize expense processes within the Transportation line, ensuring efficiency gains are tranlated into improved bottom-line performance.
- Continue investing in claims automation and analytics to further accelerate processing times and elevate customer experience.

### Sales Adoption Rate 
- Sustain investment in digital platform enhancements to keep pace with technology trends and user expectations.
- Leverage analytics to track user behavior and continuously remove friction points in the digital customer experience.
- Align sales incentives and marketing messaging to drive further adoption, especially in underpenetraded segments or regions.
- Regularly review customer feedback to identify and address emerging needs quickly, preserving the company's competitive advantage in digital distribution.

---

- Python queries on dataset generation [Python File](Data/Gen_Insurance_Dataset.ipynb)
- SQL queries on Data Exploration [SQL File](Data/Insurance_Data_Project.sql)
- Power BI file Executive Dashboard [Power BI](Data/InsuranceExecutiveDashboard.pbix)
- Excel files for deep insights analysis on [Data](Data)
