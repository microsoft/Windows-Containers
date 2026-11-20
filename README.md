# Welcome to the Windows Containers GitHub Repository

This repository is managed by the Windows Containers platform team and is dedicated to tracking features and issues related to Windows Containers. We monitor this repository to engage with our community, address questions, discuss customer scenarios, and consider feature requests.

## Getting Started

Are you new to Windows Containers? 
1. Start by setting up your local environment and running your first Windows container. Follow our documentation [here](https://aka.ms/containers/install) for a step-by-step guide.
2. Next, explore our [training module](https://learn.microsoft.com/en-us/training/paths/deploy-manage-monitor-wincontainers-aks/) to learn how to deploy, manage, monitor, and operate Windows containers.

## Product Updates

Stay informed about the latest features and improvements by visiting the [Windows Container Blog](https://techcommunity.microsoft.com/t5/containers/bg-p/Containers).

For open-source tools that enhance the Windows Containers experience, visit the [Windows Container Tools repository](https://github.com/microsoft/windows-container-tools). We encourage you to test the tools, provide feedback, and contribute to the development of Windows Container Tools.

## Troubleshooting

Encountering issues with Windows Containers? Microsoft offers a comprehensive set of resources for troubleshooting Windows Containers:

1. [Windows Containers Troubleshooting Guide](https://learn.microsoft.com/en-us/virtualization/windowscontainers/troubleshooting): This guide provides troubleshooting information for common issues encountered while working with Windows Containers.
2. [Windows Containers Troubleshooting Training Modules](https://learn.microsoft.com/en-us/training/modules/troubleshoot-windows-containers/): This training module offers a guided troubleshooting learning path for various aspects of Windows Containers.
3. [Windows Containers Troubleshooting Workshop](https://github.com/Azure-Samples/LegacyDotNetAppMigrationWorkshop/blob/main/HOL/06-windows-containers/advanced-troubleshooting.md): This lab teaches advanced techniques for configuring, troubleshooting, and debugging Windows containers.
4. [Windows Containers Networking Troubleshooting](https://techcommunity.microsoft.com/t5/networking-blog/troubleshooting-kubernetes-networking-on-windows-part-1/ba-p/508648) This article highlights step-by-step instructions for addressing common networking issues.

## Issues
For specific bugs or issues related to the Windows Container platform, please use the Issues tracker on this GitHub repository. Issues without clear reproduction steps or that remain inactive for more than two weeks will be closed.

### Feature requests

Use the [feature-request form](https://github.com/microsoft/Windows-Containers/issues/new?template=feature_request.yml) to describe an improvement, the problem it solves, and any workarounds. The form applies the `enhancement` and `triage` labels to help the team review requests. If an issue already covers your request, add your scenario to that issue instead.

Browse the consolidated [Windows Containers feature-request board](https://github.com/orgs/microsoft/projects/2576) for the backlog and public triage statuses.

Issues are public: do not include confidential information or internal work-item links. A feature request or triage status is not a commitment to implementation or a delivery date. Follow the issue for public updates.

### Monthly enhancement review (maintainers)

Project administrators can enable **Workflows > Auto-add to project**, select `microsoft/Windows-Containers`, and use `is:issue is:open label:enhancement`. This native workflow does not backfill existing issues; the initial open-request backlog has been added separately. Leave automatic issue-closing and closed-to-Delivered rules disabled: closing an issue is not proof that a feature shipped.

The **Monthly enhancement digest** GitHub Actions workflow prepares a linked report for an internal Teams channel. It runs on the first of each month at **17:17 UTC** (09:17 PST / 10:17 PDT), subject to GitHub scheduling delays. Delivery is disabled until explicitly configured:

1. In the intended Teams channel, create a Workflows flow using **When a Teams webhook request is received**, followed by posting the incoming Adaptive Card to that channel. Use the tenant-approved authentication policy; the provided sender supports a secret-bearing endpoint without a separate OAuth token, not tenant-authenticated endpoints. Assign a co-owner and configure flow failure notifications. Use Workflows rather than retired Office 365 connectors.
2. Save that endpoint as the repository Actions secret **`TEAMS_ENHANCEMENT_WEBHOOK_URL`**. Do not put the URL in an issue, source file, or workflow log. Supported endpoint hosts end in `.logic.azure.com` or `.environment.api.powerplatform.com`.
3. Merge the workflow and scripts into the default branch. From **Actions > Monthly enhancement digest > Run workflow**, leave **dry_run** enabled. Review the report in the run summary. The optional **month** input accepts `YYYY-MM`; otherwise the report covers the previous UTC calendar month.
4. Once the preview and destination are approved, set the repository Actions variable **`ENABLE_MONTHLY_ENHANCEMENT_DIGEST`** to **`true`**. Run once with **dry_run** disabled to verify end-to-end delivery. Check the Teams Workflow run history: an HTTP acceptance alone does not confirm that a channel message was posted. The monthly schedule can then send subsequent reports.

The report includes the current open enhancement inventory, requests created or closed during the reporting month, current unassigned requests, community replies for human review, and top thumbs-up counts. It reads all matching issue pages and comment pages. Community replies are filtered by author association, not proof that a customer question is unanswered. Counts use current labels, assignments, and reactions; this is not a historical snapshot or a status-change audit. A closed issue is not assumed to be shipped, and reactions do not identify distinct customers. Each list is capped with a link to the full open-request search; issue and comment bodies are not copied into Teams.

The workflow uses a read-only GitHub token and does not comment on, close, or relabel customer issues. Reports appear as the configured Teams Workflow sender, not necessarily the GitHub or Copilot app. No AI service or internal tracker is involved. Keep internal customer details and work-item links out of the public workflow and its run summary.

Scheduled runs require the workflow on the default branch and may be disabled by GitHub after 60 days of inactivity in a public repository. Monitor both GitHub Actions and Teams Workflow failures. To pause delivery, set `ENABLE_MONTHLY_ENHANCEMENT_DIGEST` to `false`. A manual preview remains available. Do not retry an uncertain submission until its Teams run history has been checked.

To check the reporting logic locally, run `.github\scripts\Test-MonthlyEnhancementDigest.ps1` in PowerShell. A read-only live preview can be generated with `.github\scripts\Send-MonthlyEnhancementDigest.ps1 -Repository microsoft/Windows-Containers -ReportPath <local-report-path>` after authenticating `gh`; omit `-Post` to avoid contacting Teams.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
