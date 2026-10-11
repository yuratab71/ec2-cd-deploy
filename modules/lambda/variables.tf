variable "function" {
  type = object({
    name         = string
    source_path  = string
    archive_path = string
  })
}

variable "env" {
  type = map(string)
}
