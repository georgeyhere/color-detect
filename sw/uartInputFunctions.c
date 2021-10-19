#include <stdio.h>
#include "platform.h"
#include "uartInputFunctions.h"
#include "xil_printf.h"
#include "xuartps.h"

#include "uartInputFunctions.h"

extern u8       BufferPtr_rx[10];
extern XUartPs  UartPs;

/**************************************************************************/
unsigned int getUartInput()
{
	int temp;
	int Output = 0;
	int Valid  = 0;

	while(!Valid)
	{
		for(int i=0; i<2; i++)
		{
			temp = charToInt( XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR) );

			if((temp > 9) || (temp < 0)) {
				Output = 0;
				break;
			}
			else {
				Output = concatentate(Output, temp);
				Valid  = (i==1);
			}
		}
	}
	return Output;
}
/**************************************************************************/
unsigned int charToInt (char a)
{
	return a - '0';
}

/**************************************************************************/
unsigned concatentate (unsigned x, unsigned y)
{
	unsigned pow = 10;
	while(y >= pow)
		pow *= 10;
	return x * pow + y;
}


