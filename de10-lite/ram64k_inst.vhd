ram64k_inst : ram64k PORT MAP (
		address	 => address_sig,
		clken	 => clken_sig,
		clock	 => clock_sig,
		data	 => data_sig,
		rden	 => rden_sig,
		wren	 => wren_sig,
		q	 => q_sig
	);
