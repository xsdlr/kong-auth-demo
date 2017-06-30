return {
  no_consumer = true,
  fields = {
    auth_server_url = {type = "url", required = true},
    auth_key_names = {type = "array", required = true, default = {}},
  }
}