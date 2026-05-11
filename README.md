# Taking the Kaplan-Meier plot as an example

## Overview
This system provides a robust solution for generating publication-quality Kaplan-Meier (survival) plots using SAS GTL (Graph Template Language). and automating configuration tasks.

## File Structure
- **`KM.sas`**: Defines the `Graphics.KM` statgraph template. It manages the visual layout, including survival curves, censored markers, diamond-shaped median indicators, and the "At Risk" table.
- **`instance_KMPlot.sas`**: Contains the `%KMPlot` macro. This script handles data preprocessing, executes `proc lifetest` for survival estimates, and performs the final rendering via `proc sgrender`.

## Key Refactoring Improvements
- **Unified Execution Logic**: Replaced large redundant code blocks with a "Dummy Group" approach, allowing the same processing loop to handle datasets both with and without `BY` variables.
- **Intelligent Label Extraction**: Automatically extracts X-axis labels and parameter titles from the `PARAM` variable or survival time variable labels.
- **Automated Excel Interaction**: Automatically generates template Excel files (`TmOpt` and `AttrMap`) if they do not exist, streamlining the workflow for customizing axis increments and strata colors.
- **Cross-Platform Pathing**: Implemented adaptive path separators to ensure seamless operation between Windows and Linux/WSL environments.

## Macro Parameter Reference (`%KMPlot`)

| Parameter | Description | Example |
| :--- | :--- | :--- |
| `DsIn` | Input dataset name | `bmt` |
| `time` | Survival time variable | `T` |
| `CnsrVar` | Censoring indicator variable | `Status` |
| `CnsrLst` | Value(s) representing censored observations | `0` |
| `by` | Grouping variable for separate plots | `SEX` |
| `strata` | Stratification variable for curves within a plot | `Group` |
| `InteractLoc` | Directory for Excel configuration files | `D:\Project\Plots` |
| `TmOpt` | Filename for time-axis tick/max options | `TmOpt.xlsx` |
| `AttrMap` | Filename for color/style mapping | `AttrMap.xlsx` |
| `PlotDs` | Final output dataset containing plot data | `FinalResults` |
| `Width/Height`| Output dimensions for the graphic | `25.8cm` / `14cm` |

## Standard Workflow
1. **Template Compilation**: Run `KM.sas` first to register the `Graphics.KM` template in your SAS environment.
2. **Data Preparation**: Ensure your input dataset contains time, status, and necessary grouping/strata variables.
3. **Initial Macro Call**: Execute the `%KMPlot` macro. If the specified `InteractLoc` does not contain `TmOpt.xlsx`, the system will automatically generate a template for you.
4. **Manual Adjustment**: Open the generated Excel file, define your `MaxTm` (X-axis limit) and `TmBy` (tick increment), then save and close.
5. **Final Rendering**: Re-run the macro. The program will read your Excel specifications and produce the final, formatted Kaplan-Meier plot.

## Technical Specifications
- SAS 9.4 or higher.
- ODS Graphics and SAS/GRAPH must be configured.
- Read/Write permissions for the local or network paths specified in `InteractLoc`.

---
*Created by Houhui Hu | Refactored for scalability and performance.*