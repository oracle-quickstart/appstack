variable "marketplace_source_images" {
  type = map(object({
    ocid = string
    is_pricing_associated = bool
    compatible_shapes = list(string)
  }))
  default = {
    main_mktpl_image = {
      ocid = "ocid1.image.oc1..aaaaaaaanbiftdebing53hkwdjnp66mlurdqdeflq2u55wlyomh76xuizehq"
      is_pricing_associated = false
      compatible_shapes = []
    }
  }
}
