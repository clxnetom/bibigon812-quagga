class quagga::zebra::access_list (
  Hash $access_lists = {},
) {
  $access_lists.each | $list_name, $list | {
    quagga_access_list { $list_name:
      * => $list
    }
  }
}
