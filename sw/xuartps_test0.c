#include <stdio.h>

#include "uartInputFunctions.h"
#include "platform.h"
#include "xil_printf.h"
#include "xuartps.h"
#include "xgpio.h"


/************************** Constant Definitions **************************/
#define UART_DEVICE_ID     XPAR_PS7_UART_1_DEVICE_ID
#define GPIO_DEVICE_ID     XPAR_AXI_GPIO_0_DEVICE_ID

/************************** Variable Definitions ***************************/
u8       BufferPtr_rx[10];
XUartPs  UartPs;

/**************************** Main Function ********************************/
int main()
{
    init_platform();

    int             Status;
    XUartPs_Config *UART_Config;

    XGpio           GPIO_inst;
    XGpio_Config   *GPIO_Config;

    unsigned int    Input;
    unsigned int    OnValue;
    unsigned int    OffValue;

    xil_printf("Device initialized.\n"); // sanity check

    // Initialize UART 1
    UART_Config = XUartPs_LookupConfig(UART_DEVICE_ID);
    Status      = XUartPs_CfgInitialize(&UartPs, UART_Config, UART_Config->BaseAddress);
    if(Status != XST_SUCCESS) {
    	xil_printf("UART initialization failed.");
    	return XST_FAILURE;
    }

    // Initialize GPIO
    GPIO_Config = XGpio_LookupConfig(GPIO_DEVICE_ID);
    Status      = XGpio_CfgInitialize(&GPIO_inst, GPIO_Config, GPIO_Config->BaseAddress);
    if(Status != XST_SUCCESS) {
    	xil_printf("GPIO initialization failed.");
    	return XST_FAILURE;
    }
    XGpio_SetDataDirection(&GPIO_inst, 1, 0x0000);

    // Get LED 'on' and 'off' values
    xil_printf("Enter a number between 00-99 that will turn on the LED. \n");
    OnValue = getUartInput();
    xil_printf("Enter a number between 00-99 that will turn off the LED. \n");
    OffValue = getUartInput();

    // Main loop
    // -> Get input through UART
    // -> Turn on or off LEDs accordingly
    while(1)
    {
    	xil_printf("Enter a two digit integer. \n");
    	Input = getUartInput();
    	xil_printf("Input Detected: %d \n", Input);

    	if(Input == OnValue)
    	{
    		xil_printf("Turning on LEDs! \n");
    		XGpio_DiscreteWrite(&GPIO_inst, 1, 0x00F0);
    	}
    	else if(Input == OffValue)
    	{
    		xil_printf("Turning off LEDs. \n");
    		XGpio_DiscreteWrite(&GPIO_inst, 1, 0x0000);
    	}
    	else
    	{
    		xil_printf("Non-control value, no change. \n");
    	}
    }

    xil_printf("End of program.");
    cleanup_platform();
    return 0;
}

