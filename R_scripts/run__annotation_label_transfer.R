# https://satijalab.org/seurat/articles/multimodal_reference_mapping.html

# Rscript /home/users/allstaff/mangiola.s/PostDoc/HPCell/R/run__annotation_label_transfer.R
# input_path_demultiplexed = "data/3_prime_batch_1/input_files/0483-002_NA.rds"
# input_path_empty_droplets = "data/3_prime_batch_1/preprocessing_results/empty_droplet_identification/0483-002_NA__empty_droplet_identification_output.rds"
# reference_azimuth_path = "/stornext/Bioinf/data/bioinf-data/Papenfuss_lab/projects/reference_azimuth.rds"
# output_path = "data/3_prime_batch_1/preprocessing_results/annotation_label_transfer/0483-002_NA__annotation_label_transfer_output.rds"


# Read arguments
args = commandArgs(trailingOnly=TRUE)
code_directory = args[[1]]
input_path_demultiplexed = args[[2]]
input_path_empty_droplets = args[[3]]
reference_azimuth_path = args[[4]]
output_path = args[[5]]

# renv::load(project = code_directory)

library(dplyr); library(tidyr); library(ggplot2)
library(Seurat)
library(tidyseurat)
library(glue)
library(SingleR)
library(celldex)
library(scuttle)
library(purrr)
library(tidySingleCellExperiment)



# Create dir
output_path |> dirname() |> dir.create( showWarnings = FALSE, recursive = TRUE)


# SingleR
sce =
  readRDS(input_path_demultiplexed) |>

  # Filter empty
  left_join(readRDS(input_path_empty_droplets), by = ".cell") |>
  tidyseurat::filter(!empty_droplet) |>
  as.SingleCellExperiment() |>
  logNormCounts()

  # # Blueprint
  # blueprint <- celldex::BlueprintEncodeData()
  # blueprint_annotation_fine =
  #   input_file_sce |>
  #  SingleR(ref = blueprint,
  #          assay.type.test=1,
  #          labels = blueprint$label.fine
  #         ) |>
  #   as_tibble(rownames = ".cell") |>
  #   select(.cell, blueprint_first.labels.fine = labels)
  #
  # blueprint_annotation_coarse =
  #   input_file_sce |>
  #   SingleR(ref = blueprint,
  #           assay.type.test=1,
  #           labels = blueprint$label.main
  #   ) |>
  #   as_tibble(rownames = ".cell") |>
  #   select(.cell, blueprint_first.labels.coarse = labels)
  #
  # rm(blueprint)
  # gc()
  #
  # # Monaco
  # MonacoImmuneData = MonacoImmuneData()
  # monaco_annotation_fine =
  #   input_file_sce |>
  #   SingleR(ref = MonacoImmuneData,
  #           assay.type.test=1,
  #           labels = MonacoImmuneData$label.fine
  #         ) |>
  #   as_tibble(rownames = ".cell") |>
  #   select(.cell, monaco_first.labels.fine = labels)
  #
  # monaco_annotation_coarse =
  #   input_file_sce |>
  #   SingleR(ref = MonacoImmuneData,
  #           assay.type.test=1,
  #           labels = MonacoImmuneData$label.main
  #   ) |>
  #   as_tibble(rownames = ".cell") |>
  #   select(.cell, monaco_first.labels.coarse = labels)
  #
  # rm(MonacoImmuneData)
  # gc()

  # # Clean
  # rm(input_file_sce)
  # gc()




  if(ncol(sce)==1){
    sce = cbind(sce, sce)
    colnames(sce)[2]= "dummy___"
  }

blueprint <- celldex::BlueprintEncodeData()


  data_singler =

          sce |>
            SingleR(
              ref = blueprint,
              assay.type.test= 1,
              labels = blueprint$label.fine
            )  |>
            as_tibble(rownames=".cell") |>
            nest(blueprint_scores_fine = starts_with("score")) |>
            select(-one_of("delta.next"),- pruned.labels) |>
            dplyr::rename( blueprint_first.labels.fine = labels) |>

    left_join(

          sce |>
            SingleR(
              ref = blueprint,
              assay.type.test= 1,
              labels = blueprint$label.main
            )  |>
            as_tibble(rownames=".cell") |>
            nest(blueprint_scores_coarse = starts_with("score")) |>
            select(-one_of("delta.next"),- pruned.labels) |>
            dplyr::rename( blueprint_first.labels.coarse = labels)
          )

  rm(blueprint)
  gc()


  MonacoImmuneData = MonacoImmuneData()

  data_singler =
    data_singler |>

    left_join(
          sce |>
            SingleR(
              ref = MonacoImmuneData,
              assay.type.test= 1,
              labels = MonacoImmuneData$label.fine
            )  |>
            as_tibble(rownames=".cell") |>

            nest(monaco_scores_fine = starts_with("score")) |>
            select(-delta.next,- pruned.labels) |>
            dplyr::rename( monaco_first.labels.fine = labels)

          ) |>

    left_join(
          sce |>
            SingleR(
              ref = MonacoImmuneData,
              assay.type.test= 1,
              labels = MonacoImmuneData$label.main
            )  |>
            as_tibble(rownames=".cell") |>

            nest(monaco_scores_coarse = starts_with("score")) |>
            select(-delta.next,- pruned.labels) |>
            dplyr::rename( monaco_first.labels.coarse = labels)
        )  |>
          filter(.cell!="dummy___")

  rm(MonacoImmuneData)
  gc()



rm(sce)
gc()

  # If not immune cells
  if(nrow(data_singler) == 0){

    tibble(.cell = character()) |>
       saveRDS(output_path)


  } else if(nrow(data_singler) <= 30){

    # If too little immune cells
    data_singler |>
      saveRDS(output_path)


  } else{

    print("Start Seurat")

    # Load reference PBMC
    # reference_azimuth <- LoadH5Seurat("data//pbmc_multimodal.h5seurat")
    # reference_azimuth |> saveRDS("analysis/annotation_label_transfer/reference_azimuth.rds")

    reference_azimuth = readRDS(reference_azimuth_path)


    # Reading input
    input_file =

      readRDS(input_path_demultiplexed) |>

      # Filter empty
      tidyseurat::left_join(readRDS(input_path_empty_droplets), by = ".cell") |>
      tidyseurat::filter(!empty_droplet)


    # Subset
    RNA_assay = input_file[["RNA"]][rownames(input_file[["RNA"]]) %in% rownames(reference_azimuth[["SCT"]]),]
    input_file <- CreateSeuratObject( counts = RNA_assay)

    if("ADT" %in% names(input_file@assays) ) ADT_assay = input_file[["ADT"]][rownames(input_file[["ADT"]]) %in% rownames(reference_azimuth[["ADT"]]),]
    if("ADT" %in% names(input_file@assays) ) input_file[["ADT"]] = ADT_assay |> CreateAssayObject()

    # Normalise RNA
    input_file =
      input_file |>

      # Normalise RNA - not informed by smartly selected variable genes
      SCTransform(assay="RNA") |>
      ScaleData(assay = "SCT") |>
      RunPCA(assay = "SCT")



    if("ADT" %in% names(input_file@assays) ){
      VariableFeatures(input_file, assay="ADT") <- rownames(input_file[["ADT"]])
      input_file =
        input_file |>
        NormalizeData(normalization.method = 'CLR', margin = 2, assay="ADT") |>
        ScaleData(assay="ADT") |>
        RunPCA(assay = "ADT", reduction.name = 'apca')
    }


    # input_file =
    #   input_file |>
    #   FindMultiModalNeighbors(
    #     reduction.list = list("pca", "apca"),
    #   dims.list = list(1:30, 1:18),
    #   modality.weight.name = "RNA.weight"
    # ) |>
    # RunUMAP(
    #   nn.name = "weighted.nn",
    #   reduction.name = "wnn.umap",
    #   reduction.key = "wnnUMAP_"
    # )



    # Define common anchors
    anchors <- FindTransferAnchors(
      reference = reference_azimuth,
      query = input_file,
      normalization.method = "SCT",
      reference.reduction = "pca",
      dims = 1:50
    )

      # Mapping
    # reference_azimuth = reference_azimuth |> RunUMAP(reduction = "pca", dims=1:50, return.model=TRUE)

      azimuth_annotation =
        tryCatch(
          expr = {
            MapQuery(
              anchorset = anchors,
              query = input_file,
              reference = reference_azimuth ,
              refdata = list(
                celltype.l1 = "celltype.l1",
                celltype.l2 = "celltype.l2" ,
                predicted_ADT = "ADT"
              ),
              reference.reduction = "spca",
              reduction.model = "umap"
            )
          },
          error = function(e){
            print(e)
            input_file |> tidyseurat::as_tibble() |> tidyseurat::select(.cell)
          }
        ) |>
        as_tibble() |>
        select(.cell, any_of(c("predicted.celltype.l1", "predicted.celltype.l2")), contains("refUMAP"))


      azimuth_annotation |>

        left_join(	data_singler	, by = join_by(.cell)	) |>

        # Save
        saveRDS(output_path)

  }
