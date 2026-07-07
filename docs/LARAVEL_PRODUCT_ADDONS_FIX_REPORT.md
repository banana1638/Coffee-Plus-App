# Laravel Product Add-ons API Fix Report

Date: 2026-07-03

Backend repository: `C:\laragon\www\Coffee-Plus`

Flutter repository: `C:\Users\LOQ\Coffee-Plus-App`

## Verified Problem

The database contains add-ons for every current product. The verified products
have between one and four related `product_addons` rows.

Runtime API inspection confirmed that both responses omit the `addons` key:

- `GET /api/dashboard`
- `GET /api/products/{id}`

`App\Http\Resources\Api\ProductResource` currently uses:

```php
'addons' => $this->whenLoaded('addons'),
```

The product detail controller does not eager-load the `addons` relationship, so
Laravel intentionally removes the key from the serialized response.

## Required Backend Fix

Update `App\Http\Controllers\API\ProductController@show` to eager-load add-ons:

```php
$product = Product::query()
    ->with([
        'addons:id,product_id,name,price,price_cents',
        'reviews' => fn ($query) => $query
            ->with('user:id,name')
            ->latest()
            ->limit(5),
    ])
    ->withAvg('reviews', 'rating')
    ->withCount('reviews')
    ->findOrFail($id);
```

The `product_id` column must remain in the selected add-on columns so Eloquent
can match each add-on to its product.

Do not add add-ons to every Dashboard product unless the Dashboard contract
explicitly requires it. Flutter now requests the full product detail when the
user opens a product, keeping the Dashboard response smaller.

## Required Response Contract

The product detail response must always contain an `addons` array when the
relationship is loaded. A product with no add-ons must return an empty array,
not omit the field.

```json
{
  "product": {
    "id": 2,
    "name": "Caffe Latte",
    "addons": [
      {
        "id": 7,
        "name": "Extra Shot",
        "price": 1.5,
        "price_cents": 150
      }
    ]
  },
  "options": {}
}
```

## Recommended Backend Tests

Add a feature test that:

1. Creates a product and two related `ProductAddon` records.
2. Calls `GET /api/products/{id}`.
3. Asserts `product.addons` contains both entries.
4. Asserts `id`, `name`, `price`, and `price_cents` are present.
5. Creates a product without add-ons and asserts `product.addons` is `[]`.

Suggested assertions:

```php
$this->getJson("/api/products/{$product->id}")
    ->assertOk()
    ->assertJsonCount(2, 'product.addons')
    ->assertJsonPath('product.addons.0.name', 'Extra Shot')
    ->assertJsonStructure([
        'product' => [
            'addons' => [
                '*' => ['id', 'name', 'price', 'price_cents'],
            ],
        ],
    ]);
```

## Flutter Status

Flutter now:

- calls `GET /api/products/{id}` when product detail opens;
- parses `{product, options}` through `ProductService`;
- uses Dashboard product data as a fallback if detail loading fails;
- treats a missing `addons` key as a backend contract problem;
- treats `addons: []` as a valid product with no add-ons;
- provides an in-app retry action without blocking the existing product view.

No Laravel files were modified by the Flutter task.
