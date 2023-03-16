use array::ArrayTrait;
use cairo_ml::math::signed_integers::i33;
use cairo_ml::math::vector::sum_two_vec;
use cairo_ml::math::tensor::Tensor;
use cairo_ml::math::tensor::tensor_new;
use cairo_ml::math::signal::valid_correlate_2d;
use cairo_ml::math::matrix::Matrix;
use cairo_ml::math::matrix::matrix_new;

use debug::print_felt;

impl Arrayi33Drop of Drop::<Array::<i33>>;
impl ArrayMatrixDrop of Drop::<Array::<Matrix>>;


fn conv2d(
    inputs: @Array::<Matrix>, kernels: @Array::<Array::<Matrix>>, biases: @Array::<Matrix>
) -> Array::<Matrix> {
    //Initialize variables
    let mut outputs = ArrayTrait::new();

    __conv2d(inputs, kernels, biases, ref outputs, 0_usize);

    return outputs;
}

fn __conv2d(
    inputs: @Array::<Matrix>,
    kernels: @Array::<Array::<Matrix>>,
    biases: @Array::<Matrix>,
    ref outputs: Array::<Matrix>,
    n: usize,
) {
    // --- Check if out of gas ---
    // TODO: Remove when automatically handled by compiler.
    match gas::get_gas() {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut data = array_new::<felt>();
            array_append::<felt>(ref data, 'OOG');
            panic(data);
        },
    }

    // --- End of the recursion ---
    if n == kernels.len() {
        return ();
    }

    let mut output_n_data = ArrayTrait::new();
    let mut acc_correlation = ArrayTrait::new();
    let mut output_n = matrix_new(0_usize, 0_usize, output_n_data);

    // --- Perform conv2d by kernel and append to the outputs ---
    conv2d_by_kernel(
        inputs, kernels.at(n), biases.at(n), ref acc_correlation, ref output_n, 0_usize
    );

    outputs.append(output_n);

    __conv2d(inputs, kernels, biases, ref outputs, n + 1_usize);
}

fn conv2d_by_kernel(
    inputs: @Array::<Matrix>,
    kernel: @Array::<Matrix>,
    bias: @Matrix,
    ref acc_correlation: Array::<i33>,
    ref output: Matrix,
    n: usize
) {
    // --- Check if out of gas ---
    // TODO: Remove when automatically handled by compiler.
    match gas::get_gas() {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut data = array_new::<felt>();
            array_append::<felt>(ref data, 'OOG');
            panic(data);
        },
    }

    // --- End of the recursion ---
    if n == kernel.len() {
        return ();
    }

    let correlation = valid_correlate_2d(inputs.at(n), kernel.at(n));

    if (n > 0_usize) {
        acc_correlation = sum_two_vec(@acc_correlation, @correlation.data);

        if n == kernel.len()
            - 1_usize {
                print_felt(10000);
                // --- Sum bias ---
                let sum = sum_two_vec(@acc_correlation, bias.data);
                output = matrix_new(rows: *bias.rows, cols: *bias.cols, data: sum);
            }
    } else {
        acc_correlation = correlation.data;
    }

    conv2d_by_kernel(inputs, kernel, bias, ref acc_correlation, ref output, n + 1_usize);
}
