<!-- badges: start -->

# HPCell

<!-- badges: end -->

HPCell is a workflow framework designed for use with single-cell RNA
sequencing studies (scRNA-seq), which helps in processing and analyzing
the vast amount of data generated by these studies. It is built on the
Targets framework within the R programming language, offering an
approachable solution for those already proficient in R. The key
features of HPCell include:

-   **Native R Pipeline:** HPCell is developed to work natively within
    the R environment, enhancing usability for R users without requiring
    them to learn new, workflow-specific languages.

-   **High Performance Computing Support:** HPCell supports scaling for
    large datasets and enables parallel processing of tasks on High
    Performance Computing platforms.

-   **Reproducibility and Consistency:** The framework ensures
    reproducibility and consistent execution environments through
    automatic dependency generation.

## Install HPCell

    remote::install_github("stemangiola/HPCell")

    library(HPCell)
    library(tidybulk)

    # # To keep the original non-tidy SummarizedExperiment view
    # options("restore_SummarizedExperiment_show" = TRUE)

## High-performance single-cell, pseudobulk random-effect modelling

### One datasets/cell-type

The interface is intuitive and consistent with `tidybulk`
`test_differential_abundance()`. By default `HPCell` uses
`test_differential_abundance(..., method = "glmmSeq_lme4")`

<!-- ```{r} -->
<!-- # Setup your job submission system -->
<!-- slurm = crew.cluster::crew_controller_slurm( -->
<!--   name = "slurm", -->
<!--   slurm_memory_gigabytes_per_cpu = 5, -->
<!--   slurm_cpus_per_task = 1, -->
<!--   workers = 200, -->
<!--   verbose = T -->
<!-- ) -->
<!-- # Perform the analyses.  -->
<!-- tidySummarizedExperiment::se |> -->
<!--   keep_abundant(factor_of_interest = dex) |> -->
<!--   # Spread the workload onto 200 workers and collects the results seamlessly -->
<!--   test_differential_abundance_hpc( -->
<!--     ~ dex + (1 | cell) -->
<!--   ) -->
<!-- ``` -->

### Many datasets/cell-types

Sometime we do pseudobulk analyses for each cell type. HPCell allows to
scale all those, in a coherent paralleisation to the HPC.

This would be the input dataset

    # A tibble: 22 × 3
       cell_type_harmonised data            formula  
       <chr>                <list>          <list>   
     1 b memory             <SmmrzdEx[,35]> <formula>
     2 b naive              <SmmrzdEx[,35]> <formula>
     3 plasma               <SmmrzdEx[,35]> <formula>
     4 ilc                  <SmmrzdEx[,38]> <formula>
     5 cd4 th1              <SmmrzdEx[,37]> <formula>
     6 cd4 th2              <SmmrzdEx[,40]> <formula>
     7 mait                 <SmmrzdEx[,26]> <formula>
     8 cd8 naive            <SmmrzdEx[,28]> <formula>
     9 cd8 tcm              <SmmrzdEx[,36]> <formula>
    10 macrophage           <SmmrzdEx[,21]> <formula>
    # ℹ 12 more rows
    # ℹ Use `print(n = ...)` to see more rows

And here the call to the `map` version of
`test_differential_abundance_hpc`

    nested_se |>
          mutate(data = map2_test_differential_abundance_hpc(
            data,
            formula ,
            computing_resources = slurm
          ))

This is the output

    # A tibble: 22 × 3
       cell_type_harmonised data            formula  
       <chr>                <list>          <list>   
     1 b memory             <SmmrzdEx[,35]> <formula>
     2 b naive              <SmmrzdEx[,35]> <formula>
     3 plasma               <SmmrzdEx[,35]> <formula>
     4 ilc                  <SmmrzdEx[,38]> <formula>
     5 cd4 th1              <SmmrzdEx[,37]> <formula>
     6 cd4 th2              <SmmrzdEx[,40]> <formula>
     7 mait                 <SmmrzdEx[,26]> <formula>
     8 cd8 naive            <SmmrzdEx[,28]> <formula>
     9 cd8 tcm              <SmmrzdEx[,36]> <formula>
    10 macrophage           <SmmrzdEx[,21]> <formula>
    # ℹ 12 more rows
    # ℹ Use `print(n = ...)` to see more rows

## High-performance single-cell preprocessing

Flowchart

<https://app.mural.co/t/covid7029/m/covid7029/1656652076667/c47e104697d76b36b8dee3bd05d8de9d96d99efd?sender=udbe1ea99c9618abb07196978>

### load input data

    # Load input data (can be a list of directories or single directory)
    library(Seurat)
    library(scRNAseq)
    input_data_path =  tempfile(tmpdir = ".") |> paste0(".rds")
    HeOrganAtlasData(ensembl=FALSE,location=FALSE)|>
      as.Seurat(data = NULL) |>
      saveRDS(input_data_path)

### Execute Targets workflow and load results

    input_data_path = "~/Documents/HPCell/file15ca234d00f5b.rds"
    # Running the pipeline
    preprocessed_seurat = run_targets_pipeline(
        input_data = input_data_path,
        tissue = "pbmc",
        filter_empty_droplets = TRUE,
        sample_column = "Tissue", 
        store = "~/Desktop"
        # debug_step = "non_batch_variation_removal_S"
    )

    ## Warning: Targets and globals must have unique names. Ignoring global objects that conflict with target names: sample_column,
    ## tissue, filter_empty_droplets. Warnings like this one are important, but if you must suppress them, you can do so with
    ## Sys.setenv(TAR_WARN = "false").

    ## ✔ skipped target reference_file

    ## ✔ skipped target tissue_file

    ## ✔ skipped target sample_column_file

    ## ✔ skipped target sample_column

    ## ✔ skipped target tissue

    ## ✔ skipped target reference_label_fine

    ## ✔ skipped target read_file

    ## ✔ skipped branch input_read_96c6c78a

    ## ✔ skipped pattern input_read

    ## ✔ skipped branch calc_UMAP_dbl_report_e2adb800

    ## ✔ skipped pattern calc_UMAP_dbl_report

    ## ✔ skipped target file

    ## ✔ skipped target filtered_file

    ## ✔ skipped target filter_empty_droplets

    ## ✔ skipped branch empty_droplets_tbl_e2adb800

    ## ✔ skipped pattern empty_droplets_tbl

    ## ✔ skipped branch cell_cycle_score_tbl_ffb33daf

    ## ✔ skipped pattern cell_cycle_score_tbl

    ## ✔ skipped target reference_read

    ## ✔ skipped branch annotation_label_transfer_tbl_ffb33daf

    ## ✔ skipped pattern annotation_label_transfer_tbl

    ## ✔ skipped branch alive_identification_tbl_338eb787

    ## ✔ skipped pattern alive_identification_tbl

    ## ✔ skipped branch doublet_identification_tbl_e59f9a16

    ## ✔ skipped pattern doublet_identification_tbl

    ## ✔ skipped branch non_batch_variation_removal_S_090a73ff

    ## ✔ skipped pattern non_batch_variation_removal_S

    ## ✔ skipped branch preprocessing_output_S_a0ced377

    ## ✔ skipped pattern preprocessing_output_S

    ## ✔ skipped branch create_pseudobulk_sample_8f97f09e

    ## ✔ skipped pattern create_pseudobulk_sample

    ## ✔ skipped target pseudobulk_merge_all_samples

    ## ✔ skipped target reference_label_coarse

    ## ✔ skipped pipeline [0.118 seconds]

    ## HPCell says: you can read your output executing tar_read(preprocessing_output_S, store = "~/Desktop")

    # Load results
    preprocessed_seurat

    ## $preprocessing_output_S_a0ced377
    ## # A Seurat-tibble abstraction: 290 × 46
    ## # [90mFeatures=9552 | Cells=290 | Active assay=SCT | Assays=originalexp, SCT[0m
    ##    .cell           orig.ident nCount_originalexp nFeature_originalexp Tissue nCount_RNA nFeature_RNA percent.mito RNA_snn_res.orig
    ##    <chr>           <fct>                   <dbl>                <int> <chr>       <int>        <int>        <dbl>            <int>
    ##  1 Bladder_cDNA_A… Bladder                  1133                  592 Bladd…       1152          610       0.0790                7
    ##  2 Bladder_cDNA_A… Bladder                  3495                 1374 Bladd…       3551         1415       0.0569               14
    ##  3 Bladder_cDNA_A… Bladder                  1297                  797 Bladd…       1599          890       0.0269               13
    ##  4 Bladder_cDNA_A… Bladder                  2071                  953 Bladd…       2355         1093       0.0412                6
    ##  5 Bladder_cDNA_A… Bladder                  2166                 1102 Bladd…       2474         1263       0.0154                5
    ##  6 Bladder_cDNA_A… Bladder                  2486                 1185 Bladd…       2734         1320       0.0640                5
    ##  7 Bladder_cDNA_A… Bladder                  3175                 1418 Bladd…       3727         1603       0.0384                0
    ##  8 Bladder_cDNA_A… Bladder                  1847                  932 Bladd…       2013         1039       0.0427                2
    ##  9 Bladder_cDNA_A… Bladder                  2546                 1104 Bladd…       2649         1139       0.0287               11
    ## 10 Bladder_cDNA_A… Bladder                   969                  574 Bladd…       1138          658       0.0387                0
    ## # ℹ 280 more rows
    ## # ℹ 37 more variables: seurat_clusters <int>, Cell_type_in_each_tissue <chr>, Cell_type_in_merged_data <chr>,
    ## #   reclustered.broad <chr>, reclustered.fine <chr>, Total <int>, LogProb <dbl>, PValue <dbl>, Limited <lgl>, FDR <dbl>,
    ## #   empty_droplet <lgl>, rank <dbl>, total <int>, fitted <dbl>, knee <dbl>, inflection <dbl>, nCount_SCT <dbl>,
    ## #   nFeature_SCT <int>, alive <lgl>, subsets_Mito_percent <dbl>, subsets_Ribo_percent <dbl>, high_mitochondrion <lgl>,
    ## #   high_ribosome <lgl>, S.Score <dbl>, G2M.Score <dbl>, Phase <chr>, scDblFinder.class <fct>, blueprint_first.labels.fine <chr>,
    ## #   blueprint_scores_fine <list>, blueprint_first.labels.coarse <chr>, blueprint_scores_coarse <list>, …

### Include reference dataset for azimuth annotation

Details to come.

    input_reference_path  <- "reference_azimuth.rds" 
    reference_url <- "https://atlas.fredhutch.org/data/nygc/multimodal/pbmc_multimodal.h5seurat" 
    download.file(reference_url, input_reference_path) 
    LoadH5Seurat(input_reference_path) |> saveRDS(input_reference_path)

# HPCell Pipeline Documentation

## Overview

The `run_targets_pipeline` function orchestrates a targeted workflow for
processing single-cell RNA sequencing data, using the `targets` R
package. This documentation explains the pipeline’s structure, methods
used, and provides code snippets to illustrate its operation. It’s
designed to help beginners understand both the how and the why of each
step.

## Pipeline arguments

Default arguments. User can adjust accordingly.

    run_targets_pipeline( store =  "./", 
                          input_reference = NULL,
                          computing_resources = crew_controller_local(workers = 1), 
                          debug_step = NULL,
                          filter_empty_droplets = TRUE, 
                          RNA_assay_name = "RNA", 
                          sample_column = "sample"
    )

User specified arguments \### 1. Input\_data

    input_data = path/to/input/dataset 

### 2. Tissue

Currently 4 options: “pbmc”, “solid”, “atypical” and “none” For example:

    tissue = "pbmc"

### 3. filter\_empty\_droplets:

TRUE = Filter dataset for empty droplets (Use this option for raw data
that has not undergone preprocessing to eliminate background noise from
empty droplets) FALSE = Skip filtering (Use this option for data sets
that are already pre-preprocessed with e.g., Empty droplet and doublet
filtering, or very small data sets)

    filter_empty_droplets = TRUE

# Documentation about the steps of the pipeline

## STEP 1: Filtering out empty droplets (function `empty_droplet_id`)

### Parameters

1.  input\_read\_RNA\_assay SingleCellExperiment object containing RNA
    assay data.
2.  filter\_empty\_droplets Logical value indicating whether to filter
    the input data.

We filter empty droplets as they don’t represent cells, but include only
ambient RNA, which is uninformative for our biological analyses.

Outputs `barcode_table` which is a tibble containing log probabilities,
FDR, and a classification indicating whether cells are empty droplets.

This step includes 4 sub steps: Filtering mitochondrial and ribosomal
genes, ranking droplets, identifying minimum threshold and removing
cells with RNA counts below this threshold

    HPCell::empty_droplet_id(input_read, filter_empty_droplets)

### 1. Filtering mitochondrial and ribosomal genes based on EnsDb.Hsapiens.v8 reference dataset

Mitochondrial and ribosomal genes exhibit expression patterns in
single-cell RNA sequencing (scRNA-seq) data that are distinct from the
patterns observed in the rest of the transcriptome. They are filtered
out to improve the quality and interpretability of scRNA-seq data,
focusing the analysis on genes more likely to yield insights

     # Genes to exclude
    location <- AnnotationDbi::mapIds(
      EnsDb.Hsapiens.v86,
      keys= BiocGenerics::rownames(input_read_RNA_assay),
      column="SEQNAME",
      keytype="SYMBOL"
      )
    mitochondrial_genes = BiocGenerics::which(location=="MT") |> names()
    ribosome_genes = BiocGenerics::rownames(input_read_RNA_assay) |> stringr::str_subset("^RPS|^RPL")

### 2. Ranking droplets

From the one with highest amount of mRNA, to the lowest amount of mRNA.
For this we use the function `barcodeRanks()`

    DropletUtils::barcodeRanks(GetAssayData(input_read_RNA_assay, assay, slot = "counts"))

### 3. Set min threshold

A minimum threshold cutoff ‘lower’ is set to exclude cells with low RNA
counts If the minimum total count is greater than 100, we exclude the
bottom 5% of barcodes by count. Otherwise lower is set to 100.

    if(min(barcode_ranks$total) < 100) { lower = 100 } else {
        lower = quantile(barcode_ranks$total, 0.05)}

### 4. Remove cells with low RNA counts

(This step will not be executed if the filter\_empty\_droplets argument
is set to FALSE, in which case all cells will be retained)

#### .cell column

-   The emptyDrops() function from dropletUtils is applied to the
    filtered data set with the lower bound set to ‘lower’ as defined
    earlier
-   True, non-empty cells are assigned to a column named ‘.cell’ in the
    output tibble “barcode\_table”

#### empty\_droplet column

-   Column empty\_droplet is added by flagging droplets as empty
    (empty\_droplet = TRUE) if their False Discovery Rate (FDR) from the
    mptyDrops test is equal to or greater than a specified significance
    threshold (in this case 0.001)

(Any droplets with missing data in the empty\_droplet column are
conservatively assumed to be empty.)

    significance_threshold = 0.001
    ... |> 
      DropletUtils::emptyDrops( test.ambient = TRUE, lower=lower) |>
      mutate(empty_droplet = FDR >= significance_threshold) 

      barcode_table <- ... |> 
      mutate( empty_droplet = FALSE)

### 5. Knee and inflection points are added to to barcode\_table

(to assisted with plotting barcode rank plot)

    barcode_table <- ... |> 
      mutate(
        knee =  metadata(barcode_ranks)$knee,
        inflection =  metadata(barcode_ranks)$inflection
        )

## STEP 2: Assign cell cycle scores based on expression of G2/M and S phase markers (function: `cell_cycle_scoring`)

### Parameters

1.  input\_read\_RNA\_assay: SingleCellExperiment object containing RNA
    assay data.
2.  empty\_droplets\_tbl: A tibble identifying empty droplets.

This step includes 2 sub steps: Normalization and cell cycle scoring.

Returns a tibble containing cell identifiers with their predicted
classification into cell cycle phases: G2M, S, or G1 phase.

    HPCell::cell_cycle_scoring(input_read,
                       empty_droplets_tbl)

### 1. normalization:

Normalize the data using the `NormalizeData` function from Seurat to
make the expression levels of genes across different cells more
comparable

     ...|>
      NormalizeData()

### 2. cell cycle scoring:

Using the `CellCycleScoring` function to assign cell cycle scores of
each cell based on its expression of G2/M and S phase markers. Stores S
and G2/M scores in object meta data along with predicted classification
of each cell in either G2M, S or G1 phase

     ...|> 
      Seurat::CellCycleScoring(  
        s.features = Seurat::cc.genes$s.genes,
        g2m.features = Seurat::cc.genes$g2m.genes,
        set.ident = FALSE 
        ) 

## STEP 3: Filtering dead cells (function `alive_identification`)

### Parameters

1.  input\_read\_RNA\_assay: SingleCellExperiment object containing RNA
    assay data.
2.  empty\_droplets\_tbl: A tibble identifying empty droplets.
3.  annotation\_label\_transfer\_tbl: A tibble with annotation label
    transfer data.

Filters out dead cells by analyzing mitochondrial and ribosomal gene
expression percentages.

Returns a tibble containing alive cells.

This step includes 6 sub-steps: Identifying chromosomal location of each
read, identifying mitochondrial genes, extracting raw `Assay` (e.g.,
RNA) count data, compute per-cell QC metrics, determine high
mitochondrion content, identify cells with unusually high ribosomal
content

    HPCell::alive_identification(input_read,
                         empty_droplets_tbl,
                         annotation_label_transfer_tbl)

### 1. Identifying chromosomal location of each read:

We retrieves the chromosome locations for genes based on their gene
symbols. - The `mapIds` function from the `AnnotationDbi` package is
used for mapping between different types of gene identifiers. - The
`EnsDb.Hsapiens.v86` Ensembl database is used as the reference data set.

    location <- AnnotationDbi::mapIds(
      EnsDb.Hsapiens.v86,
      keys=rownames(input_read_RNA_assay),
      column="SEQNAME",
      keytype="SYMBOL"
      )

### 2. identifying mitochondrial genes:

Identify the mitochondrial genes based on their symbol (starting with
“MT”)

    which_mito = rownames(input_read_RNA_assay) |> stringr::str_which("^MT")

### 3. Extracting raw `Assay` (e.g., RNA) count data

Raw count data from the the “RNA” assay is extracted using the
`GetAssayData` function from `Seurat` and stored in the “rna\_counts”
variable. This extracted data can be used for further analysis such as
normalization, scaling, identification of variable genes, etc.,

    rna_counts <- Seurat::GetAssayData(input_read_RNA_assay, layer = "counts", assay=assay)

### 4. Compute per-cell QC metrics

Quality control metrics are calculated using the `perCellQCMetrics`
function from the `scater` package. Metrics include sum of counts
(library size), and the number of detected features.

    qc_metrics <- scuttle::perCellQCMetrics(rna_counts, subsets=list(Mito=which_mito)) %>%
      dplyr::select(-sum, -detected)

### 5. Determine high mitochondrion content

-   High Mitochondrial content is identified by applying the `isOutlier`
    function from `scuttle` to the subsets\_Mito\_percent column. -
    Outliers are converted to a logical value: `TRUE` for outliers and
    `FALSE` for non-outliers.

<!-- -->

    mitochondrion <- ... |> 
      mutate(high_mitochondrion = scuttle::isOutlier(subsets_Mito_percent, type="higher"),
             high_mitochondrion = as.logical(high_mitochondrion))))

### 6. Identify cells with unusually high ribosomal content

`PercentageFeatureSet` from `Seurat` is used to compute the proportion
of counts corresponding to ribosomal genes

    subsets_Ribo_percent = Seurat::PercentageFeatureSet(input_read_RNA_assay,  pattern = "^RPS|^RPL", assay = assay

-   High ribosomal content is identified by applying the the `isOutlier`
    function from `scuttle` to the subsets\_Ribo\_percent column. - The
    outlier stays is converted to a logical value: `TRUE` for outliers
    and `FALSE` for non-outliers.

<!-- -->

    ribosome = ... |> 
      mutate(high_ribosome = scuttle::isOutlier(subsets_Ribo_percent, type="higher")) |>
      mutate(high_ribosome = as.logical(high_ribosome)) 

## STEP 4 Identifying doublets (function: `doublet_identification`)

\###Parameters: 1. input\_read\_RNA\_assay `SingleCellExperiment` object
containing RNA assay data. 2. `empty_droplets_tbl` A tibble identifying
empty droplets. 3. `alive_identification_tbl` A tibble identifying alive
cells. 4. `annotation_label_transfer_tbl` A tibble with annotation label
transfer data. 5. `reference_label_fine` Optional reference label for
fine-tuning.

Applies the `scDblFinder` algorithm to the filter\_empty\_droplets
dataset. It supports integrating with `SingleR` annotations if provided
and outputs a tibble containing cells with their associated scDblFinder
scores.

Returns a tibble containing cells with their `scDblFinder` scores

    HPCell::doublet_identification(input_read,
                                   empty_droplets_tbl,
                                   alive_identification_tbl,
                                   annotation_label_transfer_tbl,
                                   reference_label_fine)

The `scDblFinder` function from `scDblFinder` is used to detect
doublets, which are cells originating from two or more cells being
captured in the same droplet, in the scRNA-seq data. Doublets can skew
analyses and lead to incorrect interpretations, so identifying and
potentially removing them is important.

-   In our current code, clustering is set to NULL.
-   Alternatively clustering can be dynamically be set to NULL if
    reference\_label\_fine == “none” and equal to reference\_label\_fine
    if it’s provided. ( Clustering information could help identify
    outliers in clusters which may indicate doublets, or can simulate
    doublets based on clustering information )

<!-- -->

    filter_empty_droplets <- ... |> 
      scDblFinder::scDblFinder(clusters = NULL) 

## STEP 5: Add annotation labelling to data set (function `annotation_label_transfer`)

\###Parameters 1. input\_read\_RNA\_assay: `SingleCellExperiment` object
containing RNA assay data. 2. empty\_droplets\_tbl: A tibble identifying
empty droplets. 3. reference\_azimuth: Optional reference data for
Azimuth.

This step utilizes `SingleR` for cell-type identification using
reference data sets (Blueprint and Monaco Immune data). It can also
perform cell type labeling using Azimuth when a reference is provided.

This step includes 3 sub steps: Filtering and normalisation, reference
data loading, Cell Type Annotation with `MonacoImmuneData` for Fine and
Coarse Labels and cell Type Annotation with `BlueprintEncodeData` for
Fine or Coarse Labels

    HPCell::annotation_label_transfer(input_read,
                                      empty_droplets_tbl,
                                      reference_read)

### 1. Filtering and normalisation

-   Cells flagged as empty\_droplet are removed from the dataset using
    the `filter` function from dplyr.
-   `logNormCounts` is used to apply log-normalization to the count
    data. This helps to make the gene expression levels more comparable
    across cells.

<!-- -->

    sce = ... |> 
      dplyr::filter(!empty_droplet) |>
      scuttle::logNormCounts()

### 2. Reference data loading

Load cell type reference data from `BlueprintEncodeData` and
`MonacoImmuneData` provided by the `celldex` package for cell annotation
based on gene expression profiles

    blueprint <- celldex::BlueprintEncodeData()
    MonacoImmuneData = celldex::MonacoImmuneData()

### 3. Cell Type Annotation with `MonacoImmuneData` for Fine and Coarse Labels

(depending on the tissue type selected by the user)

-   Performs cell type annotation using `SingleR` with the
    `MonacoImmuneData` reference with fine-grained cell type labels and
    coarse-grained labels
-   Creates column `blueprint_first.labels.fine` and
    `blueprint_first.labels.coarse` which contains scores on the likely
    cell type that each read belongs to

<!-- -->

    data_annotated =
        SingleR::SingleR(
          ref = blueprint,
          assay.type.test= 1,
          labels = blueprint$label.fine
          ) |>
        rename(blueprint_first.labels.fine = labels) |>
      
      SingleR::SingleR(
        ref = blueprint,
        assay.type.test= 1,
        labels = blueprint$label.main
        ) |>
      as_tibble(rownames=".cell") |>
      nest(blueprint_scores_coarse = starts_with("score")) |>
      select(-one_of("delta.next"),- pruned.labels) |>
      rename( blueprint_first.labels.coarse = labels))

### 4.Cell Type Annotation with `BlueprintEncodeData` for Fine and Coarse Labels

-   Performs cell type annotation using `SingleR` with the `blueprint`
    reference with fine-grained cell type labels and coarse-grained
    labels.
-   Creates column monaco\_first.labels.fine and
    monaco\_first.labels.coarse which contains scores on the likely cell
    type that each read belongs to

<!-- -->

    data_annotated = ... |> 
      sce |>
      SingleR::SingleR(
        ref = MonacoImmuneData,
        assay.type.test= 1,
        labels = MonacoImmuneData$label.fine
        )  
          
        ... |>
          SingleR::SingleR(
            ref = MonacoImmuneData,
            assay.type.test = 1,
            labels = MonacoImmuneData$label.main
            ) 

## STEP 6 Data normalisation (function: `non_batch_variation_removal`)

Regressing out variations due to mitochondrial content, ribosomal
content, and cell cycle effects.

### Parameters

1.  `input_read_RNA_assay` Path to demultiplexed data.
2.  `empty_droplets_tbl` Path to empty droplets data.
3.  `alive_identification_tbl` A tibble from alive cell identification.
4.  `cell_cycle_score_tbl` A tibble from cell cycle scoring.

Returns normalized and adjusted data

This step includes 3 sub-steps: Construction of `counts` data frame,
data normalization with `SCTransform` and normalization with
`NormalizeData`

     HPCell::non_batch_variation_removal(input_read,
                                         empty_droplets_tbl,
                                         alive_identification_tbl,
                                         cell_cycle_score_tbl)

### 1. Construction of `counts` data frame:

We construct the `counts` data frame by aggregating outputs from
empty\_droplets\_tbl, alive\_identification\_tbl and
cell\_cycle\_score\_tbl. - We exclude empty droplets from initial raw
count data. - Next we incorporate ribosomal and mitochondrial
percentages which offer insights into cellular health and metabolic
activity - Finally we add cell cycle G2/M score to each cell’s profile.

    counts = ... |> 
      left_join(empty_droplets_tbl, by = ".cell") |>
      dplyr::filter(!empty_droplet) |>
      left_join(
        HPCell::alive_identification_tbl |>
          select(.cell, subsets_Ribo_percent, subsets_Mito_percent),
        by=".cell"
        ) |>
      left_join(
        cell_cycle_score_tbl |>
          select(.cell, G2M.Score),
        by=".cell"
        )

### 2. Data normalization with `SCTransform`:

We apply the `SCTransform` function to apply variance-stabilizing
transformation (VST) to `counts` which normalizes and scales the data
and also performs feature selection and controls for confounding
factors. This results in data that is better suited for downstream
analysis such as dimensionality reduction and differential expression
analysis.

    normalized_rna <- Seurat::SCTransform(
        counts, 
        assay=assay,
        return.only.var.genes=FALSE,
        residual.features = NULL,
        vars.to.regress = c("subsets_Mito_percent", "subsets_Ribo_percent", "G2M.Score"),
        vst.flavor = "v2",
        scale_factor=2186
      )

### 3. Normalization with `NormalizeData`:

If the `ADT` assay is present, we further normalize our `counts` data
using the centered log ratio (CLR) normalization method. This mitigates
the effects of varying total protein expression across cells. If the
`ADT` assay is absent, we can simply omit this step.

    # If "ADT" assay is present
    ... |> 
      Seurat::NormalizeData(normalization.method = 'CLR', margin = 2, assay="ADT") 

## STEP 7 Creating individual pseudo bulk samples (function: `create_pseudobulk`)

### Parameters

1.  pre-processing\_output\_S: Processed dataset from preprocessing
2.  assays: assay used, default = “RNA”
3.  x: User defined character vector for c(Tissue,
    Cell\_type\_in\_each\_tissue)

-   Aggregates cells based on sample and cell type annotations, creating
    pseudobulk samples for each combination. Handles RNA and ADT assays.

-   Returns a list containing pseudo bulk data aggregated by sample and
    by both sample and cell type.

<!-- -->

    HPCell::create_pseudobulk(preprocessing_output_S,   assays = "RNA",  x = c(Tissue, Cell_type_in_each_tissue))

We apply some data manipulation steps to get unique feature because RNA
and ADT both can have similarly named genes. In our data set we may
contain information on both RNA and ADT assays: - RNA: Measures the
abundance of RNA molecules for different genes within a cell. - ADT:
Quantifies protein levels on the cell surface using antibodies tagged
with DNA bar codes, which are then detected alongside RNA.

The challenge arises because both RNA and ADT data might include
identifiers (gene names for RNA, protein names for ADT) that could be
the same or very similar. However, they represent different types of
biological molecules (nucleic acids vs. proteins). To accurately analyze
and distinguish between these two data types in a combined data set, we
need to ensure that each feature (whether it’s an RNA-measured gene or
an ADT-measured protein) has a unique identifier. Thus we apply these
data manipulation steps:

### 1.Cell aggregation by tissue and cell type

Cells are aggregated based on the `Tissue` and
`Cell_type_in_each_tissue` columns. By summarizing single-cell data into
groups, it mimics traditional bulk RNA-seq data while retaining the
ability to dissect biological variability at a finer resolution

    # Aggregate cells
    ... |> 
      tidySingleCellExperiment::aggregate_cells(!!x, slot = "data", assays=assays) 
