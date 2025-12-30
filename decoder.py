def decode_uart_result(hex_string):
    clean_hex = hex_string.replace(" ", "").replace("0x", "").strip()
    
    if len(clean_hex) != 10:
        print(f"Error: Expected 10 hex characters, got {len(clean_hex)} ('{clean_hex}')")
        return None

    try:
        full_value = int(clean_hex, 16)
   
        integer_part = (full_value >> 20) & 0xFFFF
        
   
        fraction_part = full_value & 0xFFFFF

        decimal_result = integer_part + (fraction_part / 1048576.0)
        
        return decimal_result

    except ValueError:
        print("Error: Invalid Hex characters.")
        return None

if __name__ == "__main__":
    print("--- FPGA Square Root Decoder (Q16.20) ---")
    print("Type 'exit' to quit.\n")
    
    while True:
        user_input = input("Enter Hex Result (e.g., '00 00 A0 00 00'): ")
        
        if user_input.lower() in ['exit', 'quit']:
            break
            
        result = decode_uart_result(user_input)
        
        if result is not None:
            print(f"Decimal Result: {result:.6f}")
            print(f"Squared Check:  {result**2:.6f}") # Helps verify if it's correct
            print("-" * 30)