{application, asn1,
 [{description, "The Erlang ASN1 compiler version 1.6.17"},
  {vsn, "1.6.17"},
  {modules, [
	asn1rt,
	asn1rt_per_bin,
	asn1rt_per_bin_rt2ct,
	asn1rt_uper_bin,
	asn1rt_ber_bin,
	asn1rt_ber_bin_v2,
	asn1rt_check,
	asn1rt_driver_handler
             ]},
  {registered, [
	asn1_ns,
	asn1db,
	asn1_driver_owner
		]},
  {env, []},
  {applications, [kernel, stdlib]}
  ]}.
