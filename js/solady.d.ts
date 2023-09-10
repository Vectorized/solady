/**
 * Accompanying JavaScript library for Solady.
 *
 * To install:
 *
 * ```
 * npm install solady
 * ```
 *
 * Module exports:
 *
 * - `LibZip`
 *   - `flzCompress(data)`: Compresses hex encoded data with FastLZ.
 *   - `flzDecompress(data)`: Decompresses hex encoded data with FastLZ.
 *   - `cdCompress(data)`: Compresses hex encoded calldata.
 *   - `cdDecompress(data)`: Decompresses hex encoded calldata.
 *
 * - `ERC1967Factory`
 *   - `address`: Canonical address of Solady's ERC1967Factory.
 *   - `abi`: ABI of Solady's ERC1967Factory.
 */
declare module "solady" {
    /**
     * FastLZ and calldata compression / decompression functions.
     */
    namespace LibZip {
        /**
         * Compresses hex encoded data with the FastLZ LZ77 algorithm.
         * @param data - A hex encoded string representing the original data.
         * @returns The compressed result as a hex encoded string.
         */
        function flzCompress(data: string): string;
        /**
         * Decompresses hex encoded data with the FastLZ LZ77 algorithm.
         * @param data - A hex encoded string representing the compressed data.
         * @returns The decompressed result as a hex encoded string.
         */
        function flzDecompress(data: string): string;
        /**
         * Compresses hex encoded calldata.
         * @param data - A hex encoded string representing the original data.
         * @returns The compressed result as a hex encoded string.
         */
        function cdCompress(data: string): string;
        /**
         * Decompresses hex encoded calldata.
         * @param data - A hex encoded string representing the compressed data.
         * @returns The decompressed result as a hex encoded string.
         */
        function cdDecompress(data: string): string;
    }
    /**
     * ERC1967Factory canonical address and ABI.
     */
    namespace ERC1967Factory {
        /**
         * Canonical address of Solady's ERC1967Factory.
         */
        var address: string;
        /**
         * ABI of Solady's ERC1967Factory.
         */
        var abi: any;
    }
}

