# Quy trình Thiết lập và Sử dụng Tài liệu API tự động với Swagger

Tài liệu này hướng dẫn cách thiết lập, sử dụng và bảo trì hệ thống tài liệu API tự động bằng OpenAPI (Swagger) trong dự án. Hệ thống này được xây dựng dựa trên nguyên tắc **Code as Documentation**, nghĩa là tài liệu được sinh ra trực tiếp từ mã nguồn, đảm bảo tính chính xác và luôn được cập nhật.

## 1. Tổng quan về Công nghệ

- **OpenAPI Specification:** Tiêu chuẩn để mô tả RESTful API.
- **Swagger UI:** Công cụ để hiển thị tài liệu OpenAPI một cách trực quan và có tính tương tác.
- **Zod:** Thư viện để định nghĩa schema và validation dữ liệu.
- **`@asteasolutions/zod-to-openapi`:** Thư viện "cầu nối", giúp chuyển đổi các Zod schema thành tài liệu OpenAPI.
- **`swagger-ui-express`:** Middleware để tích hợp Swagger UI vào ứng dụng Express.

---

## 2. Cài đặt và Thiết lập ban đầu

Phần này chỉ cần thực hiện một lần duy nhất cho dự án.

### Bước 1: Cài đặt các thư viện cần thiết

```bash
npm install swagger-ui-express @asteasolutions/zod-to-openapi js-yaml
npm install -D @types/swagger-ui-express @types/js-yaml
```

### Bước 2: Cấu trúc thư mục

Đảm bảo bạn có cấu trúc thư mục sau để chứa các file liên quan đến tài liệu:

```
src/
├── docs/
│   ├── api/               # Thư mục chứa file openapi.yaml được sinh ra
│   │   └── openapi.yaml
│   ├── generate-openapi.ts  # Script để tạo tài liệu
│   └── openapi.registry.ts  # File đăng ký trung tâm
└── shared/
    └── dto/               # Thư mục chứa các Data Transfer Objects
        ├── auth.dto.ts
        ├── common.dto.ts
        └── index.ts         # Barrel file để export các DTO
```

### Bước 3: Thêm script vào `package.json`

Thêm script `docs:generate` vào file `package.json` để có thể dễ dàng chạy bộ tạo tài liệu.

```json
// package.json
"scripts": {
  // ... các script khác
  "docs:generate": "ts-node -r tsconfig-paths/register src/docs/generate-openapi.ts",
  "dev": "..."
},
```

### Bước 4: Tích hợp Swagger UI vào ứng dụng

Trong file `src/index.ts`, thêm đoạn code sau để phục vụ trang tài liệu Swagger UI khi chạy ở môi trường development.

```typescript
// src/index.ts
import swaggerUi from 'swagger-ui-express';
import yaml from 'js-yaml';
import fs from 'fs';
import path from 'path';

// ... các middleware khác

// --- API Docs ---
if (config.NODE_ENV === 'development') {
  try {
    const openApiPath = path.resolve(process.cwd(), 'docs/api/openapi.yaml');
    const file = fs.readFileSync(openApiPath, 'utf8');
    const swaggerDocument = yaml.load(file);

    if (typeof swaggerDocument === 'object' && swaggerDocument !== null) {
      app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
    } else {
      console.error('Failed to load a valid OpenAPI specification.');
    }
  } catch (error) {
    console.error('Could not read or parse OpenAPI YAML file.', error);
  }
}

// --- API Routes ---
app.use('/api/v1', v1Routes);

// ...
```

---

## 3. Quy trình làm việc khi thêm/sửa API

Đây là quy trình bạn sẽ lặp lại mỗi khi phát triển một tính năng mới.

### Bước 1: Tạo hoặc cập nhật DTO (Data Transfer Object)

- **Nơi tạo:** `src/shared/dto/`
- **Nội dung:** Định nghĩa các Zod schema cho dữ liệu đầu vào (request body, query, params) và cả dữ liệu trả về (response).
- **Ví dụ:** Tạo DTO cho việc đăng ký user trong `src/shared/dto/auth.dto.ts`.

```typescript
// src/shared/dto/auth.dto.ts
import { z } from 'zod';

export const RegisterUserDto = z.object({
  email: z.string(),
  password: z.string().min(8),
  name: z.string(),
});
```

- **Quan trọng:** Đừng quên export DTO mới từ file `src/shared/dto/index.ts`.

```typescript
// src/shared/dto/index.ts
export * from './auth.dto';
export * from './common.dto';
// export * from './new-module.dto'; // Thêm dòng này khi có module mới
```

### Bước 2: "Trang trí" Route với thông tin OpenAPI

- **Nơi thực hiện:** Trong file route của module (ví dụ: `src/modules/auth/auth.route.ts`).
- **Cách làm:** Sử dụng `registry.registerPath()` để mô tả chi tiết về endpoint.

```typescript
// src/modules/auth/auth.route.ts
import { registry } from '@/docs/openapi.registry';
import { RegisterUserDto } from '@/shared/dto/auth.dto';
import { ConflictDto } from '@/shared/dto/common.dto';

// ...

registry.registerPath({
  method: 'post',
  path: '/api/v1/auth/register', // Đường dẫn đầy đủ của API
  summary: 'Register a new user',    // Tóm tắt ngắn gọn
  tags: ['Auth'],                    // Gom nhóm API theo module
  request: {
    body: {
      content: {
        'application/json': {
          schema: RegisterUserDto, // **Liên kết DTO cho request body**
        },
      },
    },
  },
  responses: {
    '201': { // Mã status code thành công
      description: 'User created successfully',
      content: {
        'application/json': {
          schema: z.object({ data: UserResponseDto }), // **Định nghĩa schema cho response thành công**
        },
      },
    },
    '409': { // Mã status code lỗi
      description: 'Email already taken',
      content: {
        'application/json': {
          schema: ConflictDto, // **Liên kết DTO cho response lỗi**
        },
      },
    },
  },
});

router.post('/register', validate(authValidation.register), authController.register);
```

**Lưu ý:**
- `summary` và `description` giúp người khác hiểu API của bạn làm gì.
- `tags` giúp gom nhóm các API liên quan đến nhau trong giao diện Swagger.
- `request` và `responses` là nơi bạn liên kết các DTO đã tạo để mô tả dữ liệu vào và ra.

### Bước 3: Tái tạo tài liệu và xem kết quả

1.  **Chạy lệnh generate:**
    ```bash
    npm run docs:generate
    ```
    Lệnh này sẽ đọc các `registry.registerPath` bạn vừa thêm và cập nhật lại file `docs/api/openapi.yaml`.

2.  **Khởi động server:**
    ```bash
    npm run dev
    ```

3.  **Xem tài liệu:** Mở trình duyệt và truy cập [http://localhost:3001/api-docs](http://localhost:3001/api-docs) (thay port nếu cần). Bạn sẽ thấy API mới của mình xuất hiện, sẵn sàng để xem và dùng thử.

---

## 4. Khi nào cần chạy lại `npm run docs:generate`?

Bạn chỉ cần chạy lại lệnh này khi:

- Bạn thêm một API mới.
- Bạn thay đổi đường dẫn, phương thức (method) của một API cũ.
- Bạn thay đổi cấu trúc dữ liệu của request hoặc response (tức là sửa đổi các DTO liên quan).

Bạn **không** cần chạy lại lệnh này nếu chỉ thay đổi logic bên trong controller hoặc service.
