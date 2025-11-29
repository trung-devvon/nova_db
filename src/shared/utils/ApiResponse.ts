import { Response } from 'express';

class ApiResponse<T> {
  constructor(
    public statusCode: number,
    public message: string = 'Success',
    public data?: T
  ) {}

  send(res: Response): void {
    const responsePayload: { success: boolean; message: string; data?: T } = {
      success: this.statusCode < 400,
      message: this.message,
    };

    if (this.data !== undefined) {
      responsePayload.data = this.data;
    }

    res.status(this.statusCode).json(responsePayload);
  }
}

export default ApiResponse;
